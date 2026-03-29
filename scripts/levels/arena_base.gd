class_name ArenaBase
extends Node2D

## Base class for all combat arenas.
## Draws isometric floor, spawns enemies from room data, manages clear condition.

signal room_cleared

var enemy_scene: PackedScene = preload("res://scenes/enemies/base_enemy.tscn")
var slime_data: EnemyData = preload("res://resources/enemy_data/slime_data.tres")

var arena_radius: float = 520.0
var tile_w: int = 96
var tile_h: int = 48
var grid_count: int = 8
var enemies_to_spawn: int = 4
var enemies_spawned: bool = false
var room_is_cleared: bool = false
var spawn_initial_wave: bool = true
var restore_carried_health: bool = true
var room_clear_enabled: bool = true

@onready var entity_layer: Node2D = $EntityLayer

var _vignette_shader: Shader = preload("res://shaders/vignette.gdshader")

func _ready() -> void:
	queue_redraw()
	_configure_from_current_room()
	_setup_vignette()

	if spawn_initial_wave:
		# Spawn enemies after a brief delay so the scene is fully assembled first.
		await get_tree().create_timer(0.5).timeout
		_spawn_enemies()

	if restore_carried_health:
		# Restore player health after the player has finished entering the tree.
		await get_tree().process_frame
		_restore_player_health()

func _draw() -> void:
	# Dark void background
	draw_rect(Rect2(-2000, -1500, 4000, 3000), Color(0.03, 0.03, 0.05, 1.0))

	for ix in range(-grid_count, grid_count + 1):
		for iy in range(-grid_count, grid_count + 1):
			var screen_x: float = float(ix - iy) * (tile_w * 0.5)
			var screen_y: float = float(ix + iy) * (tile_h * 0.5)

			if absi(ix) + absi(iy) > grid_count:
				continue

			var is_light: bool = (ix + iy) % 2 == 0
			var floor_color: Color
			if is_light:
				floor_color = Color(0.14, 0.16, 0.22, 1.0)
			else:
				floor_color = Color(0.11, 0.13, 0.18, 1.0)

			# Ambient depth gradient — darken tiles further from center
			var edge_dist := absi(ix) + absi(iy)
			var depth_t: float = float(edge_dist) / float(grid_count)
			floor_color = floor_color.darkened(depth_t * 0.25)

			# Edge tiles get a fiery border tint
			if edge_dist == grid_count:
				floor_color = Color(0.12, 0.06, 0.04, 1.0)
			elif edge_dist == grid_count - 1:
				floor_color = floor_color.lerp(Color(0.15, 0.08, 0.05, 1.0), 0.3)

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
			# Right-south edge (bottom-right face)
			var right_edge := PackedVector2Array([
				points[1],  # right vertex
				points[2],  # bottom vertex
				Vector2(points[2].x, points[2].y + edge_h),
				Vector2(points[1].x, points[1].y + edge_h),
			])
			draw_colored_polygon(right_edge, side_color)
			# Left-south edge (bottom-left face)
			var left_edge := PackedVector2Array([
				points[2],  # bottom vertex
				points[3],  # left vertex
				Vector2(points[3].x, points[3].y + edge_h),
				Vector2(points[2].x, points[2].y + edge_h),
			])
			draw_colored_polygon(left_edge, side_color.darkened(0.15))

			# Grid lines - brighter near edges for lava glow feel
			var line_alpha := 0.3
			var line_r := 0.22
			if edge_dist >= grid_count - 1:
				line_alpha = 0.6
				line_r = 0.5
			var line_color := Color(line_r, 0.2, 0.15, line_alpha)
			draw_polyline(PackedVector2Array([
				points[0], points[1], points[2], points[3], points[0]
			]), line_color, 1.0)

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
	for i in range(enemies_to_spawn):
		_spawn_enemy_in_radius(200.0, 450.0)
	enemies_spawned = true

func _on_room_cleared() -> void:
	room_cleared.emit()

	# Save player health for next room
	var player: CharacterBody2D = GameManager.get_player()
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

func _setup_vignette() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)

	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = _vignette_shader
	rect.material = mat
	layer.add_child(rect)

## Override in subclasses to place obstacles
func _place_obstacles() -> void:
	pass

func _add_obstacle(type: Obstacle.ObstacleType, pos: Vector2) -> void:
	var obs := Obstacle.new()
	entity_layer.add_child(obs)
	obs.setup(type, pos)

func _configure_from_current_room() -> void:
	if GameManager.current_room:
		enemies_to_spawn = GameManager.current_room.enemy_count

func _restore_player_health() -> void:
	if GameManager.player_health_carry <= 0.0:
		return

	var player: CharacterBody2D = GameManager.get_player()
	if player == null or not player.has_node("HealthComponent"):
		return

	var health: HealthComponent = player.get_node("HealthComponent")
	health.set_current_health(GameManager.player_health_carry)

func _clamp_player_to_arena() -> void:
	var player: CharacterBody2D = GameManager.get_player()
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
