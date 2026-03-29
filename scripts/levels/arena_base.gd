class_name ArenaBase
extends Node2D

## Base class for all combat arenas.
## Draws isometric floor, spawns enemies from room data, manages clear condition.

signal room_cleared

var enemy_scene: PackedScene = preload("res://scenes/enemies/base_enemy.tscn")
var slime_data: EnemyData = preload("res://resources/enemy_data/slime_data.tres")

var arena_radius: float = 1100.0
var tile_w: int = 96
var tile_h: int = 48
var grid_count: int = 18
var enemies_to_spawn: int = 4
var enemies_spawned: bool = false
var room_is_cleared: bool = false
var spawn_initial_wave: bool = true
var restore_carried_health: bool = true
var room_clear_enabled: bool = true

@onready var entity_layer: Node2D = $EntityLayer

var _vignette_shader: Shader = preload("res://shaders/vignette.gdshader")
var _low_health_shader: Shader = preload("res://shaders/low_health.gdshader")
var _low_health_material: ShaderMaterial = null

## Floor theme — set in subclasses before super._ready() for distinct visual identity.
enum FloorTheme { ANTECHAMBER, MAGMA_CORRIDOR, RITUAL, MOLTEN_THRONE }
var floor_theme: FloorTheme = FloorTheme.ANTECHAMBER

## Per-theme color palettes for The Ember Sanctum.
var _floor_palettes: Dictionary = {
	FloorTheme.ANTECHAMBER: {
		"tile_light": Color(0.16, 0.17, 0.22),
		"tile_dark": Color(0.12, 0.13, 0.18),
		"edge_inner": Color(0.15, 0.08, 0.05),
		"edge_outer": Color(0.22, 0.08, 0.04),
		"line_color": Color(0.22, 0.2, 0.15, 0.3),
		"line_edge": Color(0.5, 0.2, 0.15, 0.6),
		"void_color": Color(0.03, 0.03, 0.05),
		"accent": Color(0.8, 0.45, 0.15),
		"ambient_tint": Color(0.55, 0.5, 0.65),
		"light_color": Color(1.0, 0.9, 0.7),
	},
	FloorTheme.MAGMA_CORRIDOR: {
		"tile_light": Color(0.14, 0.12, 0.16),
		"tile_dark": Color(0.10, 0.08, 0.12),
		"edge_inner": Color(0.30, 0.10, 0.04),
		"edge_outer": Color(0.45, 0.12, 0.02),
		"line_color": Color(0.35, 0.15, 0.08, 0.35),
		"line_edge": Color(0.7, 0.25, 0.08, 0.7),
		"void_color": Color(0.04, 0.02, 0.02),
		"accent": Color(1.0, 0.5, 0.1),
		"ambient_tint": Color(0.55, 0.42, 0.38),
		"light_color": Color(1.0, 0.75, 0.5),
	},
	FloorTheme.RITUAL: {
		"tile_light": Color(0.14, 0.13, 0.20),
		"tile_dark": Color(0.10, 0.09, 0.16),
		"edge_inner": Color(0.18, 0.06, 0.18),
		"edge_outer": Color(0.25, 0.06, 0.22),
		"line_color": Color(0.22, 0.15, 0.25, 0.3),
		"line_edge": Color(0.5, 0.15, 0.5, 0.6),
		"void_color": Color(0.03, 0.02, 0.05),
		"accent": Color(0.7, 0.3, 0.9),
		"ambient_tint": Color(0.50, 0.42, 0.58),
		"light_color": Color(0.9, 0.75, 1.0),
	},
	FloorTheme.MOLTEN_THRONE: {
		"tile_light": Color(0.12, 0.10, 0.10),
		"tile_dark": Color(0.08, 0.06, 0.06),
		"edge_inner": Color(0.50, 0.15, 0.03),
		"edge_outer": Color(0.70, 0.20, 0.03),
		"line_color": Color(0.40, 0.18, 0.08, 0.4),
		"line_edge": Color(0.8, 0.3, 0.1, 0.8),
		"void_color": Color(0.05, 0.02, 0.01),
		"accent": Color(1.0, 0.6, 0.15),
		"ambient_tint": Color(0.55, 0.35, 0.30),
		"light_color": Color(1.0, 0.8, 0.5),
	},
}

var _palette: Dictionary = {}  ## Active palette, set in _pick_room_palette()

func _ready() -> void:
	_pick_room_palette()
	queue_redraw()
	_configure_from_current_room()
	_setup_vignette()
	_setup_lighting()
	_setup_low_health_overlay()
	_spawn_ambient_particles()
	_spawn_floor_decals()

	if spawn_initial_wave:
		# Spawn enemies after a brief delay so the scene is fully assembled first.
		await get_tree().create_timer(0.5).timeout
		_spawn_enemies()

	if restore_carried_health:
		# Restore player health after the player has finished entering the tree.
		await get_tree().process_frame
		_restore_player_health()

func _draw() -> void:
	var p: Dictionary = _palette if not _palette.is_empty() else _floor_palettes[FloorTheme.ANTECHAMBER]

	# Dark void background
	var void_col: Color = p["void_color"]
	void_col.a = 1.0
	draw_rect(Rect2(-3000, -2000, 6000, 4000), void_col)

	# --- Edge glow ring outside tile boundary ---
	_draw_edge_glow(p)

	# --- Distant wall silhouettes ---
	_draw_wall_silhouettes(p)

	for ix in range(-grid_count, grid_count + 1):
		for iy in range(-grid_count, grid_count + 1):
			var screen_x: float = float(ix - iy) * (tile_w * 0.5)
			var screen_y: float = float(ix + iy) * (tile_h * 0.5)

			if absi(ix) + absi(iy) > grid_count:
				continue

			var is_light: bool = (ix + iy) % 2 == 0
			var floor_color: Color = p["tile_light"] if is_light else p["tile_dark"]

			# Per-tile color variation for organic look
			var tile_hash: float = fmod(absf(sin(float(ix * 73 + iy * 137))), 1.0)
			floor_color = floor_color.lightened((tile_hash - 0.5) * 0.08)

			# Ambient depth gradient — darken tiles further from center
			var edge_dist := absi(ix) + absi(iy)
			var depth_t: float = float(edge_dist) / float(grid_count)
			floor_color = floor_color.darkened(depth_t * 0.25)

			# Edge tiles get ember border tint from palette
			if edge_dist == grid_count:
				floor_color = p["edge_outer"]
			elif edge_dist == grid_count - 1:
				floor_color = floor_color.lerp(p["edge_inner"], 0.3)

			var hw: float = tile_w * 0.5
			var hh: float = tile_h * 0.5
			var points := PackedVector2Array([
				Vector2(screen_x, screen_y - hh),
				Vector2(screen_x + hw, screen_y),
				Vector2(screen_x, screen_y + hh),
				Vector2(screen_x - hw, screen_y),
			])
			draw_colored_polygon(points, floor_color)

			# South-facing tile edge for 3D thickness
			var edge_h: float = 5.0
			var side_color: Color = floor_color.darkened(0.4)
			var right_edge := PackedVector2Array([
				points[1], points[2],
				Vector2(points[2].x, points[2].y + edge_h),
				Vector2(points[1].x, points[1].y + edge_h),
			])
			draw_colored_polygon(right_edge, side_color)
			var left_edge := PackedVector2Array([
				points[2], points[3],
				Vector2(points[3].x, points[3].y + edge_h),
				Vector2(points[2].x, points[2].y + edge_h),
			])
			draw_colored_polygon(left_edge, side_color.darkened(0.15))

			# Grid lines from palette — brighter near edges
			var line_col: Color = p["line_color"] if edge_dist < grid_count - 1 else p["line_edge"]
			draw_polyline(PackedVector2Array([
				points[0], points[1], points[2], points[3], points[0]
			]), line_col, 1.0)

			# Floor cracks on ~15% of tiles (seeded by tile_hash)
			if tile_hash < 0.15:
				_draw_tile_cracks(points, floor_color, tile_hash)

	# Lava veins for hot themes
	if floor_theme == FloorTheme.MAGMA_CORRIDOR or floor_theme == FloorTheme.MOLTEN_THRONE:
		_draw_lava_veins(p)

	# Rune circle for ritual/boss themes
	if floor_theme == FloorTheme.RITUAL or floor_theme == FloorTheme.MOLTEN_THRONE:
		_draw_floor_runes(p)

func _draw_tile_cracks(points: PackedVector2Array, base_color: Color, seed_val: float) -> void:
	## Draw 2-3 hairline cracks on a tile for weathered stone look.
	var center := (points[0] + points[2]) * 0.5
	var crack_color := base_color.darkened(0.35)
	crack_color.a = 0.5
	var num_cracks: int = 2 + int(seed_val * 8.0) % 2
	for c in range(num_cracks):
		var angle: float = seed_val * TAU * float(c + 1) * 2.7
		var length: float = 8.0 + seed_val * 12.0
		var start := center + Vector2(cos(angle) * 3.0, sin(angle) * 1.5)
		var end := start + Vector2(cos(angle) * length, sin(angle) * length * 0.5)
		draw_line(start, end, crack_color, 1.0)

func _draw_lava_veins(p: Dictionary) -> void:
	## Draw glowing vein lines between tiles in the outer ring of the arena.
	var vein_color: Color = p["edge_outer"]
	vein_color.a = 0.25
	var outer_start: int = int(grid_count * 0.65)
	for ix in range(-grid_count, grid_count + 1):
		for iy in range(-grid_count, grid_count + 1):
			var edge_dist := absi(ix) + absi(iy)
			if edge_dist < outer_start or edge_dist > grid_count:
				continue
			var hash_val: float = fmod(absf(sin(float(ix * 31 + iy * 97))), 1.0)
			if hash_val > 0.3:
				continue
			var sx: float = float(ix - iy) * (tile_w * 0.5)
			var sy: float = float(ix + iy) * (tile_h * 0.5)
			var hw: float = tile_w * 0.5
			# Draw a short glowing segment along one tile edge
			var intensity: float = float(edge_dist - outer_start) / float(grid_count - outer_start)
			var vc: Color = vein_color
			vc.a = vein_color.a + intensity * 0.2
			draw_line(Vector2(sx, sy - tile_h * 0.5), Vector2(sx + hw, sy), vc, 1.5)

func _draw_floor_runes(p: Dictionary) -> void:
	## Draw a large rune circle at arena center for ritual/boss themes.
	var accent: Color = p["accent"]
	accent.a = 0.18
	var rune_radius: float = 180.0
	var segments: int = 24
	var circle_points := PackedVector2Array()
	for i in range(segments + 1):
		var angle: float = float(i) / float(segments) * TAU
		circle_points.append(Vector2(cos(angle) * rune_radius, sin(angle) * rune_radius * 0.5))
	draw_polyline(circle_points, accent, 1.5)

	# Inner star pattern
	if floor_theme == FloorTheme.RITUAL:
		var star_points: int = 6
		for i in range(star_points):
			var a1: float = float(i) / float(star_points) * TAU
			var a2: float = float(i + 2) / float(star_points) * TAU
			var r: float = rune_radius * 0.7
			draw_line(
				Vector2(cos(a1) * r, sin(a1) * r * 0.5),
				Vector2(cos(a2) * r, sin(a2) * r * 0.5),
				accent, 1.0)
	else:
		# Concentric circles for molten throne
		for ring in range(1, 3):
			var r: float = rune_radius * (0.4 + ring * 0.15)
			var inner_points := PackedVector2Array()
			for i in range(segments + 1):
				var angle: float = float(i) / float(segments) * TAU
				inner_points.append(Vector2(cos(angle) * r, sin(angle) * r * 0.5))
			var ring_color := accent
			ring_color.a = 0.12
			draw_polyline(inner_points, ring_color, 1.0)

func _draw_edge_glow(p: Dictionary) -> void:
	## Radial glow ring just outside the tile boundary, replacing stark black void.
	var glow_color: Color = p["edge_outer"]
	glow_color.a = 0.10
	var base_radius: float = float(grid_count) * tile_w * 0.5
	var glow_extent: float = 120.0
	var seg_count: int = 28
	for i in range(seg_count):
		var a1: float = float(i) / float(seg_count) * TAU
		var a2: float = float(i + 1) / float(seg_count) * TAU
		# Inner ring at tile edge
		var inner1 := Vector2(cos(a1) * base_radius, sin(a1) * base_radius * 0.5)
		var inner2 := Vector2(cos(a2) * base_radius, sin(a2) * base_radius * 0.5)
		# Outer ring fades to nothing
		var outer1 := Vector2(cos(a1) * (base_radius + glow_extent), sin(a1) * (base_radius + glow_extent) * 0.5)
		var outer2 := Vector2(cos(a2) * (base_radius + glow_extent), sin(a2) * (base_radius + glow_extent) * 0.5)
		var fade_color := Color(glow_color.r, glow_color.g, glow_color.b, 0.0)
		# Two triangles per segment
		draw_colored_polygon(PackedVector2Array([inner1, inner2, outer2]), PackedColorArray([glow_color, glow_color, fade_color]))
		draw_colored_polygon(PackedVector2Array([inner1, outer2, outer1]), PackedColorArray([glow_color, fade_color, fade_color]))

func _draw_wall_silhouettes(p: Dictionary) -> void:
	## Draw faint dark rectangles at distance suggesting dungeon walls.
	var wall_color: Color = p["void_color"]
	wall_color = wall_color.lightened(0.03)
	var seed_base: float = float(grid_count * 7 + int(floor_theme) * 13)
	for i in range(7):
		var angle: float = fmod(seed_base + float(i) * 1.3, TAU)
		var dist: float = 1300.0 + fmod(absf(sin(seed_base + float(i) * 2.1)), 1.0) * 500.0
		var cx: float = cos(angle) * dist
		var cy: float = sin(angle) * dist * 0.5
		var w: float = 80.0 + fmod(absf(sin(float(i) * 3.7)), 1.0) * 200.0
		var h: float = 120.0 + fmod(absf(sin(float(i) * 5.3)), 1.0) * 180.0
		draw_rect(Rect2(cx - w * 0.5, cy - h, w, h), wall_color)

func _physics_process(_delta: float) -> void:
	_clamp_player_to_arena()

	if room_clear_enabled:
		_check_room_clear()

func _clamp_entity_to_arena(entity: Node2D) -> void:
	var pos: Vector2 = entity.global_position
	var ix: float = absf(pos.x)
	var iy: float = absf(pos.y) * 2.0
	if ix + iy > arena_radius:
		var scale_factor: float = arena_radius / (ix + iy)
		entity.global_position = pos * scale_factor

func _spawn_enemies() -> void:
	# Stagger enemy engagement so the player isn't overwhelmed frame-1.
	# Each enemy waits progressively longer before chasing, giving card windows.
	for i in range(enemies_to_spawn):
		var enemy: Node = _spawn_enemy_in_radius(300.0, 650.0)
		if enemy and enemy.has_method("set_aggro_delay"):
			enemy.set_aggro_delay(i * 0.8)
	enemies_spawned = true

func _on_room_cleared() -> void:
	room_cleared.emit()

	# Save player health for next room
	var player: PlayerController = GameManager.get_player()
	if player and player.has_node("HealthComponent"):
		var health: HealthComponent = player.get_node("HealthComponent")
		GameManager.player_health_carry = health.current_health

	# Mark room as completed
	if GameManager.current_room:
		GameManager.complete_room(GameManager.current_room.room_id)

	# Show "Room Cleared" text with dramatic entrance
	var is_boss := GameManager.current_room and GameManager.current_room.room_type == RoomData.RoomType.BOSS

	var label := Label.new()
	label.text = "VICTORY!" if is_boss else "ROOM CLEARED!"
	label.add_theme_font_size_override("font_size", 52)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.6, 0.2, 0.0, 0.9))
	label.add_theme_constant_override("outline_size", 4)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.position = Vector2(-250, -40)
	label.size = Vector2(500, 80)

	# Start invisible and scaled up for slam-in effect
	label.modulate.a = 0.0
	label.pivot_offset = Vector2(250, 40)
	label.scale = Vector2(2.0, 2.0)

	var ui_layer: CanvasLayer = get_node_or_null("UILayer")
	if ui_layer:
		ui_layer.add_child(label)
	else:
		add_child(label)

	# Slam in with screen shake
	ScreenFX.shake(self, 10.0, 0.2)
	var anim := create_tween()
	anim.set_parallel(true)
	anim.tween_property(label, "modulate:a", 1.0, 0.15)
	anim.tween_property(label, "scale", Vector2(1.0, 1.0), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	anim.chain()
	# Gentle pulse while visible
	anim.tween_property(label, "scale", Vector2(1.05, 1.05), 0.5).set_ease(Tween.EASE_IN_OUT)
	anim.tween_property(label, "scale", Vector2(1.0, 1.0), 0.5).set_ease(Tween.EASE_IN_OUT)

	if is_boss:
		await get_tree().create_timer(3.0).timeout
		GameManager.run_active = false
		GameManager.go_to_class_select()
	else:
		await get_tree().create_timer(1.5).timeout
		_show_card_rewards()

func _show_card_rewards() -> void:
	## Show card reward screen before returning to map.
	var reward_scene: PackedScene = load("res://scenes/ui/card_reward_screen.tscn")
	var reward_screen: CardRewardScreen = reward_scene.instantiate() as CardRewardScreen
	if reward_screen == null:
		return

	var is_elite: bool = GameManager.current_room and GameManager.current_room.room_type == RoomData.RoomType.ELITE
	var class_id: StringName = &"soldier"
	if GameManager.current_class_config:
		class_id = GameManager.current_class_config.class_id

	var ui_layer: CanvasLayer = get_node_or_null("UILayer")
	if ui_layer:
		ui_layer.add_child(reward_screen)
	else:
		add_child(reward_screen)

	reward_screen.setup(class_id, is_elite)
	reward_screen.card_chosen.connect(func(card: CardData) -> void:
		GameManager.add_card_to_deck(card)
		GameManager.go_to_map()
	)
	reward_screen.rewards_skipped.connect(func() -> void:
		GameManager.go_to_map()
	)

func _spawn_ambient_particles() -> void:
	var particle_layer := Node2D.new()
	particle_layer.z_index = -1
	particle_layer.name = "AmbientParticles"
	add_child(particle_layer)

	var p: Dictionary = _palette if not _palette.is_empty() else _floor_palettes[FloorTheme.ANTECHAMBER]
	var accent: Color = p["accent"]

	# Interior motes — theme-colored
	for i in range(15):
		var mote := Sprite2D.new()
		var size := randi_range(2, 4)
		var alpha := randf_range(0.08, 0.2)
		var col := accent.lightened(randf_range(-0.1, 0.2))
		col.a = alpha
		mote.texture = PlaceholderSprites.create_circle_texture(size, col)
		mote.position = Vector2(randf_range(-600, 600), randf_range(-400, 400))
		mote.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		particle_layer.add_child(mote)
		_animate_mote(mote, false)

	# Edge embers — spawn along arena perimeter, drift upward
	for i in range(20):
		var mote := Sprite2D.new()
		var size := randi_range(2, 3)
		var col := accent
		col.a = randf_range(0.25, 0.5)
		mote.texture = PlaceholderSprites.create_circle_texture(size, col)
		mote.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		particle_layer.add_child(mote)
		_animate_mote(mote, true)

	# Falling ash for hot themes
	if floor_theme == FloorTheme.MAGMA_CORRIDOR or floor_theme == FloorTheme.MOLTEN_THRONE:
		for i in range(12):
			var ash := Sprite2D.new()
			ash.texture = PlaceholderSprites.create_circle_texture(2, Color(0.25, 0.22, 0.2, 0.15))
			ash.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			particle_layer.add_child(ash)
			_animate_ash(ash)

func _animate_mote(mote: Sprite2D, is_edge: bool) -> void:
	if not is_instance_valid(mote) or not mote.is_inside_tree():
		return

	var duration := randf_range(3.0, 6.0)
	var start_pos: Vector2
	var drift: Vector2

	if is_edge:
		# Start at arena perimeter
		var angle: float = randf() * TAU
		var edge_r: float = arena_radius * randf_range(0.8, 1.0)
		start_pos = Vector2(cos(angle) * edge_r, sin(angle) * edge_r * 0.5)
		drift = Vector2(randf_range(-20, 20), randf_range(-50, -20))
	else:
		start_pos = Vector2(randf_range(-600, 600), randf_range(-400, 400))
		drift = Vector2(randf_range(-30, 30), randf_range(-40, -15))

	mote.position = start_pos
	mote.modulate.a = 0.0

	var tween := mote.create_tween()
	tween.tween_property(mote, "modulate:a", 1.0, duration * 0.2)
	tween.tween_property(mote, "position", start_pos + drift, duration * 0.6)
	tween.tween_property(mote, "modulate:a", 0.0, duration * 0.2)
	tween.tween_callback(_animate_mote.bind(mote, is_edge))

func _animate_ash(ash: Sprite2D) -> void:
	if not is_instance_valid(ash) or not ash.is_inside_tree():
		return

	var duration := randf_range(4.0, 8.0)
	var start_pos := Vector2(randf_range(-500, 500), randf_range(-400, -200))
	ash.position = start_pos
	ash.modulate.a = 0.0

	var tween := ash.create_tween()
	tween.tween_property(ash, "modulate:a", 1.0, duration * 0.15)
	tween.tween_property(ash, "position", start_pos + Vector2(randf_range(-40, 40), randf_range(150, 300)), duration * 0.7)
	tween.tween_property(ash, "modulate:a", 0.0, duration * 0.15)
	tween.tween_callback(_animate_ash.bind(ash))

func _setup_vignette() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)

	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = _vignette_shader
	var p: Dictionary = _palette if not _palette.is_empty() else _floor_palettes[FloorTheme.ANTECHAMBER]
	mat.set_shader_parameter("tint_color", p["edge_outer"])
	rect.material = mat
	layer.add_child(rect)

func _setup_low_health_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 6
	add_child(layer)

	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_low_health_material = ShaderMaterial.new()
	_low_health_material.shader = _low_health_shader
	_low_health_material.set_shader_parameter("health_ratio", 1.0)
	rect.material = _low_health_material
	layer.add_child(rect)

	# Connect to player health updates after the player is ready
	await get_tree().process_frame
	var player: PlayerController = GameManager.get_player()
	if player and player.has_node("HealthComponent"):
		var health: HealthComponent = player.get_node("HealthComponent")
		health.health_changed.connect(_on_player_health_changed)
		_on_player_health_changed(health.current_health, health.max_health)

func _on_player_health_changed(current: float, maximum: float) -> void:
	if _low_health_material:
		_low_health_material.set_shader_parameter("health_ratio", current / maxf(maximum, 1.0))

## Override in subclasses to place obstacles
func _place_obstacles() -> void:
	pass

func _add_obstacle(type: Obstacle.ObstacleType, pos: Vector2) -> void:
	var obs := Obstacle.new()
	entity_layer.add_child(obs)
	obs.setup(type, pos)

func _add_grass_cluster(center: Vector2, count: int = 3, spread: float = 30.0) -> void:
	## Spawn a cluster of grass patches around a center point.
	for i in range(count):
		var patch := GrassPatch.new()
		var offset := Vector2(randf_range(-spread, spread), randf_range(-spread * 0.5, spread * 0.5))
		entity_layer.add_child(patch)
		patch.setup(center + offset, randi_range(3, 5))

func _spawn_random_grass(count: int = 8) -> void:
	## Scatter grass patches randomly within the arena for ambient decoration.
	var max_dist: float = arena_radius * 0.7
	for i in range(count):
		var angle: float = randf() * TAU
		var dist: float = randf_range(50.0, max_dist)
		var pos := Vector2(cos(angle) * dist, sin(angle) * 0.5 * dist)
		_add_grass_cluster(pos, randi_range(1, 3), 20.0)

func _add_decoration(type: ArenaDecoration.DecorType, pos: Vector2) -> void:
	var p: Dictionary = _palette if not _palette.is_empty() else _floor_palettes[FloorTheme.ANTECHAMBER]
	var decor := ArenaDecoration.new()
	entity_layer.add_child(decor)
	decor.setup(type, pos, p["accent"])

func _spawn_random_decorations(count: int = 6) -> void:
	## Scatter decorations randomly within the arena for visual richness.
	var max_dist: float = arena_radius * 0.6
	for i in range(count):
		var angle: float = randf() * TAU
		var dist: float = randf_range(80.0, max_dist)
		var pos := Vector2(cos(angle) * dist, sin(angle) * 0.5 * dist)
		# Weighted random: rubble 40%, bones 30%, chain 20%, brazier 10%
		var roll: float = randf()
		var type: ArenaDecoration.DecorType
		if roll < 0.4:
			type = ArenaDecoration.DecorType.RUBBLE
		elif roll < 0.7:
			type = ArenaDecoration.DecorType.BONES
		elif roll < 0.9:
			type = ArenaDecoration.DecorType.CHAIN
		else:
			type = ArenaDecoration.DecorType.BRAZIER
		_add_decoration(type, pos)

func _configure_from_current_room() -> void:
	if GameManager.current_room:
		enemies_to_spawn = GameManager.current_room.enemy_count

func _restore_player_health() -> void:
	if GameManager.player_health_carry <= 0.0:
		return

	var player: PlayerController = GameManager.get_player()
	if player == null or not player.has_node("HealthComponent"):
		return

	var health: HealthComponent = player.get_node("HealthComponent")
	health.set_current_health(GameManager.player_health_carry)

func _clamp_player_to_arena() -> void:
	var player: PlayerController = GameManager.get_player()
	if player:
		_clamp_entity_to_arena(player)

func _check_room_clear() -> void:
	if enemies_spawned and not room_is_cleared and GameManager.get_enemies().is_empty():
		room_is_cleared = true
		_on_room_cleared()

func _spawn_enemy_in_radius(min_radius: float, max_radius: float) -> Node:
	return _spawn_enemy_at_offset(_get_spawn_offset(min_radius, max_radius))

func _pick_enemy_data() -> EnemyData:
	## Pick a random enemy type from the room's pool, falling back to slime.
	if GameManager.current_room and not GameManager.current_room.enemy_types.is_empty():
		return GameManager.current_room.enemy_types.pick_random()
	return slime_data

func _spawn_enemy_at_offset(offset: Vector2) -> Node:
	if enemy_scene == null or entity_layer == null:
		return null

	var data: EnemyData = _pick_enemy_data()
	var enemy: Node2D = enemy_scene.instantiate() as Node2D
	if enemy == null:
		return null
	enemy.set("enemy_data", data)
	enemy.global_position = offset
	entity_layer.add_child(enemy)

	# Apply tier-based difficulty scaling
	if GameManager.current_room:
		DifficultyScaler.scale_enemy(enemy, GameManager.current_room.tier)

	return enemy

func _get_spawn_offset(min_radius: float, max_radius: float) -> Vector2:
	var angle: float = randf() * TAU
	var radius: float = randf_range(min_radius, max_radius)
	return Vector2(cos(angle), sin(angle) * 0.5) * radius

var _theme_set_by_subclass: bool = false

func _pick_room_palette() -> void:
	## Set floor theme based on room type. Subclasses can override floor_theme
	## before calling super._ready() for full control — that takes priority.
	if not _theme_set_by_subclass and GameManager.current_room:
		match GameManager.current_room.room_type:
			RoomData.RoomType.ELITE:
				floor_theme = FloorTheme.RITUAL
			RoomData.RoomType.BOSS:
				floor_theme = FloorTheme.MOLTEN_THRONE
			_:
				# Higher tiers get hotter palette
				if GameManager.current_room.tier >= 2:
					floor_theme = FloorTheme.MAGMA_CORRIDOR
	_palette = _floor_palettes[floor_theme]

func _setup_lighting() -> void:
	## Add CanvasModulate for ambient tint and a PointLight2D on the player.
	var p: Dictionary = _palette if not _palette.is_empty() else _floor_palettes[FloorTheme.ANTECHAMBER]
	var canvas_mod := CanvasModulate.new()
	canvas_mod.color = p["ambient_tint"]
	add_child(canvas_mod)

	# Player torch light — attached after a frame so the player node is ready.
	await get_tree().process_frame
	var player: PlayerController = GameManager.get_player()
	if player:
		var light := PointLight2D.new()
		light.texture = _create_light_texture()
		light.color = p["light_color"]
		light.energy = 1.2
		light.texture_scale = 3.5
		light.shadow_enabled = false
		light.name = "PlayerLight"
		player.add_child(light)

func _create_light_texture() -> Texture2D:
	## Generate a soft radial gradient texture for PointLight2D.
	var size: int = 128
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size / 2.0, size / 2.0)
	for x in range(size):
		for y in range(size):
			var dist: float = Vector2(x, y).distance_to(center) / (size / 2.0)
			var alpha: float = clampf(1.0 - dist * dist, 0.0, 1.0)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(image)

func _spawn_floor_decals() -> void:
	## Scatter semi-transparent floor details for visual richness.
	var decal_layer := Node2D.new()
	decal_layer.z_index = -2
	decal_layer.name = "FloorDecals"
	add_child(decal_layer)

	var max_dist: float = arena_radius * 0.8
	for i in range(12):
		var angle: float = randf() * TAU
		var dist: float = randf_range(40.0, max_dist)
		var pos := Vector2(cos(angle) * dist, sin(angle) * 0.5 * dist)

		var decal := Sprite2D.new()
		# Randomly pick between crack lines and scorch marks
		if randf() < 0.5:
			decal.texture = _make_crack_decal()
		else:
			decal.texture = _make_scorch_decal()
		decal.position = pos
		decal.rotation = randf() * TAU
		decal.modulate.a = randf_range(0.08, 0.2)
		decal.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		decal_layer.add_child(decal)

func _make_crack_decal() -> ImageTexture:
	var size: int = 32
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0
	var cy: float = size / 2.0
	# Draw 2-3 jagged crack lines from center
	for _line_idx in range(randi_range(2, 3)):
		var angle: float = randf() * TAU
		var steps: int = randi_range(4, 7)
		var px: float = cx
		var py: float = cy
		for _s in range(steps):
			angle += randf_range(-0.6, 0.6)
			var step_len: float = randf_range(2.0, 5.0)
			var nx: float = px + cos(angle) * step_len
			var ny: float = py + sin(angle) * step_len
			# Bresenham-lite: just plot points along the line
			for t in range(int(step_len) + 1):
				var lx: int = clampi(int(lerpf(px, nx, float(t) / maxf(step_len, 1.0))), 0, size - 1)
				var ly: int = clampi(int(lerpf(py, ny, float(t) / maxf(step_len, 1.0))), 0, size - 1)
				img.set_pixel(lx, ly, Color(0.2, 0.18, 0.15, 0.8))
			px = nx
			py = ny
	return ImageTexture.create_from_image(img)

func _make_scorch_decal() -> ImageTexture:
	var size: int = 24
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size / 2.0, size / 2.0)
	var radius: float = size / 2.0
	for x in range(size):
		for y in range(size):
			var dist: float = Vector2(x, y).distance_to(center)
			if dist < radius:
				var t: float = dist / radius
				var alpha: float = (1.0 - t * t) * 0.6
				img.set_pixel(x, y, Color(0.08, 0.06, 0.04, alpha))
	return ImageTexture.create_from_image(img)
