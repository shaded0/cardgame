extends Node2D

## Base class for all combat arenas.
## Draws isometric floor, spawns enemies from room data, manages clear condition.

signal room_cleared

var enemy_scene: PackedScene = preload("res://scenes/enemies/base_enemy.tscn")
var slime_data: Resource = preload("res://resources/enemy_data/slime_data.tres")

var arena_radius: float = 520.0
var tile_w: int = 96
var tile_h: int = 48
var grid_count: int = 8
var enemies_to_spawn: int = 4
var enemies_spawned: bool = false
var room_is_cleared: bool = false

@onready var entity_layer: Node2D = $EntityLayer

func _ready() -> void:
	queue_redraw()

	# Load room data from GameManager
	if GameManager.current_room:
		enemies_to_spawn = GameManager.current_room.enemy_count

	# Spawn enemies after a brief delay
	await get_tree().create_timer(0.5).timeout
	_spawn_enemies()

	# Restore player health from previous room
	await get_tree().process_frame
	if GameManager.player_health_carry > 0:
		var players: Array[Node] = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			var health: HealthComponent = players[0].get_node("HealthComponent")
			health.current_health = GameManager.player_health_carry
			health.health_changed.emit(health.current_health, health.max_health)

func _draw() -> void:
	draw_rect(Rect2(-2000, -1500, 4000, 3000), Color(0.06, 0.06, 0.08, 1.0))

	for ix in range(-grid_count, grid_count + 1):
		for iy in range(-grid_count, grid_count + 1):
			var screen_x: float = float(ix - iy) * (tile_w * 0.5)
			var screen_y: float = float(ix + iy) * (tile_h * 0.5)

			if absi(ix) + absi(iy) > grid_count:
				continue

			var is_light: bool = (ix + iy) % 2 == 0
			var floor_color: Color
			if is_light:
				floor_color = Color(0.16, 0.19, 0.24, 1.0)
			else:
				floor_color = Color(0.13, 0.16, 0.20, 1.0)

			if absi(ix) + absi(iy) == grid_count:
				floor_color = floor_color.darkened(0.3)

			var hw: float = tile_w * 0.5
			var hh: float = tile_h * 0.5
			var points := PackedVector2Array([
				Vector2(screen_x, screen_y - hh),
				Vector2(screen_x + hw, screen_y),
				Vector2(screen_x, screen_y + hh),
				Vector2(screen_x - hw, screen_y),
			])
			draw_colored_polygon(points, floor_color)

			var line_color := Color(0.22, 0.26, 0.32, 0.4)
			draw_polyline(PackedVector2Array([
				points[0], points[1], points[2], points[3], points[0]
			]), line_color, 1.0)

func _physics_process(_delta: float) -> void:
	# Clamp player inside arena
	var player_node: Node2D = entity_layer.get_node_or_null("Player")
	if player_node:
		_clamp_entity_to_arena(player_node)

	# Check room clear condition
	if enemies_spawned and not room_is_cleared:
		var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
		if enemies.size() == 0:
			room_is_cleared = true
			_on_room_cleared()

func _clamp_entity_to_arena(entity: Node2D) -> void:
	var pos: Vector2 = entity.global_position
	var ix: float = absf(pos.x)
	var iy: float = absf(pos.y) * 2.0
	if ix + iy > arena_radius:
		var scale_factor: float = arena_radius / (ix + iy)
		entity.global_position = pos * scale_factor

func _spawn_enemies() -> void:
	for i in range(enemies_to_spawn):
		var enemy: Node = enemy_scene.instantiate()
		enemy.enemy_data = slime_data

		var angle: float = randf() * TAU
		var radius: float = 200.0 + randf() * 250.0
		var offset: Vector2 = Vector2(cos(angle), sin(angle) * 0.5) * radius
		enemy.global_position = offset

		entity_layer.add_child(enemy)
	enemies_spawned = true

func _on_room_cleared() -> void:
	room_cleared.emit()

	# Save player health for next room
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var health: HealthComponent = players[0].get_node("HealthComponent")
		GameManager.player_health_carry = health.current_health

	# Mark room as completed
	if GameManager.current_room:
		GameManager.complete_room(GameManager.current_room.room_id)

	# Show "Room Cleared" text
	var label := Label.new()
	label.text = "ROOM CLEARED!"
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1.0))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.position = Vector2(-200, -30)
	label.size = Vector2(400, 60)

	# Add to UI layer
	var ui_layer: CanvasLayer = get_node_or_null("UILayer")
	if ui_layer:
		ui_layer.add_child(label)
	else:
		add_child(label)

	# Check if boss — show victory instead
	if GameManager.current_room and GameManager.current_room.room_type == 3:  # BOSS
		label.text = "VICTORY!"
		label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
		await get_tree().create_timer(3.0).timeout
		GameManager.run_active = false
		get_tree().change_scene_to_file("res://scenes/ui/class_select.tscn")
	else:
		await get_tree().create_timer(1.5).timeout
		get_tree().change_scene_to_file("res://scenes/map/map.tscn")

## Override in subclasses to place obstacles
func _place_obstacles() -> void:
	pass

func _add_obstacle(type: int, pos: Vector2) -> void:
	var obs := StaticBody2D.new()
	obs.set_script(load("res://scripts/levels/obstacle.gd"))
	entity_layer.add_child(obs)
	obs.setup(type, pos)
