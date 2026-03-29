extends Node2D

## Test arena setup script.
## Draws a debug isometric-style floor and handles simple timed enemy spawning bounds.

@onready var entity_layer: Node2D = $EntityLayer

## Preloaded scene/data keeps this test arena easy to reskin later.
var enemy_scene: PackedScene = preload("res://scenes/enemies/base_enemy.tscn")
var slime_data: Resource = preload("res://resources/enemy_data/slime_data.tres")

var spawn_timer: float = 3.5
var max_enemies: int = 6
var spawn_radius_min: float = 300.0
var spawn_radius_max: float = 500.0
var time_since_spawn: float = 1.0

# Arena boundary
const ARENA_RADIUS: float = 520.0

func _ready() -> void:
	# Request a redraw at startup so floor tiles render immediately.
	queue_redraw()

func _draw() -> void:
	# `_draw()` is called by queue_redraw(); we use procedural geometry instead of a tilemap.
	# Dark background
	draw_rect(Rect2(-2000, -1500, 4000, 3000), Color(0.06, 0.06, 0.08, 1.0))

	# Draw isometric diamond floor tiles
	var tile_w: int = 96
	var tile_h: int = 48
	var grid_count: int = 8

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

			# Edge tiles are darker to hint at boundary
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

func _physics_process(delta: float) -> void:
	# Spawn timer is tracked in physics time so spawn rhythm is stable.
	time_since_spawn -= delta
	if time_since_spawn <= 0.0:
		time_since_spawn = spawn_timer
		_try_spawn()

	# Clamp player inside arena
	_clamp_entity_to_arena($EntityLayer/Player)

func _clamp_entity_to_arena(entity: Node2D) -> void:
	if entity == null:
		return
	var pos: Vector2 = entity.global_position
	# Use diamond/isometric boundary: |x| + |2y| < radius
	var ix: float = absf(pos.x)
	var iy: float = absf(pos.y) * 2.0
	if ix + iy > ARENA_RADIUS:
		# Push back inside
		var scale_factor: float = ARENA_RADIUS / (ix + iy)
		entity.global_position = pos * scale_factor

func _try_spawn() -> void:
	var current_enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	if current_enemies.size() >= max_enemies:
		return

	var enemy: Node = enemy_scene.instantiate()
	enemy.enemy_data = slime_data

	# Spawn within arena bounds
	var angle: float = randf() * TAU
	var radius: float = spawn_radius_min + randf() * (spawn_radius_max - spawn_radius_min)
	var offset: Vector2 = Vector2(cos(angle), sin(angle) * 0.5) * radius
	enemy.global_position = offset

	entity_layer.add_child(enemy)
