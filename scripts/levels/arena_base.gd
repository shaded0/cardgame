class_name ArenaBase
extends Node2D

## Base class for all combat arenas.
## Coordinates floor rendering, arena visuals, and encounter flow helpers.

signal room_cleared

const ArenaFloorRenderer = preload("res://scripts/levels/arena_floor_renderer.gd")
const ArenaVisuals = preload("res://scripts/levels/arena_visuals.gd")
const ArenaFlow = preload("res://scripts/levels/arena_flow.gd")

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

enum FloorTheme { ANTECHAMBER, MAGMA_CORRIDOR, RITUAL, MOLTEN_THRONE }
var floor_theme: FloorTheme = FloorTheme.ANTECHAMBER
var _palette: Dictionary = {}
var _theme_set_by_subclass: bool = false

var _floor_renderer: RefCounted
var _visuals: RefCounted
var _flow: RefCounted

func _ready() -> void:
	_floor_renderer = ArenaFloorRenderer.new(self)
	_visuals = ArenaVisuals.new(self)
	_flow = ArenaFlow.new(self)

	_pick_room_palette()
	queue_redraw()
	_configure_from_current_room()
	_visuals.setup_vignette(_palette, _vignette_shader)
	_visuals.setup_lighting(_palette)
	_low_health_material = _visuals.setup_low_health_overlay(_low_health_shader)
	_visuals.connect_low_health_overlay(_low_health_material, _on_player_health_changed)
	_visuals.spawn_ambient_particles(_palette, floor_theme, arena_radius)
	_visuals.spawn_floor_decals(arena_radius)

	if spawn_initial_wave:
		await get_tree().create_timer(0.5).timeout
		_spawn_enemies()

	if restore_carried_health:
		await get_tree().process_frame
		_restore_player_health()

func _draw() -> void:
	_floor_renderer.draw_floor(_palette, floor_theme, grid_count, tile_w, tile_h)

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
	enemies_spawned = _flow.spawn_enemies(enemies_to_spawn)

func _on_room_cleared() -> void:
	await _flow.handle_room_cleared()

func _on_player_health_changed(current: float, maximum: float) -> void:
	_visuals.update_low_health_overlay(_low_health_material, current, maximum)

## Override in subclasses to place obstacles
func _place_obstacles() -> void:
	pass

func _add_obstacle(type: Obstacle.ObstacleType, pos: Vector2) -> void:
	var obs := Obstacle.new()
	entity_layer.add_child(obs)
	obs.setup(type, pos)

func _add_grass_cluster(center: Vector2, count: int = 3, spread: float = 30.0) -> void:
	for _patch_index in range(count):
		var patch := GrassPatch.new()
		var offset := Vector2(randf_range(-spread, spread), randf_range(-spread * 0.5, spread * 0.5))
		entity_layer.add_child(patch)
		patch.setup(center + offset, randi_range(3, 5))

func _spawn_random_grass(count: int = 8) -> void:
	var max_dist: float = arena_radius * 0.7
	for _grass_index in range(count):
		var angle: float = randf() * TAU
		var dist: float = randf_range(50.0, max_dist)
		var pos := Vector2(cos(angle) * dist, sin(angle) * 0.5 * dist)
		_add_grass_cluster(pos, randi_range(1, 3), 20.0)

func _add_decoration(type: ArenaDecoration.DecorType, pos: Vector2) -> void:
	var decor := ArenaDecoration.new()
	entity_layer.add_child(decor)
	decor.setup(type, pos, _palette["accent"])

func _spawn_random_decorations(count: int = 6) -> void:
	var max_dist: float = arena_radius * 0.6
	for _decor_index in range(count):
		var angle: float = randf() * TAU
		var dist: float = randf_range(80.0, max_dist)
		var pos := Vector2(cos(angle) * dist, sin(angle) * 0.5 * dist)
		var type: ArenaDecoration.DecorType
		var roll: float = randf()
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
	enemies_to_spawn = _flow.configure_from_current_room(enemies_to_spawn)

func _restore_player_health() -> void:
	_flow.restore_player_health()

func _clamp_player_to_arena() -> void:
	var player: PlayerController = GameManager.get_player()
	if player:
		_clamp_entity_to_arena(player)

func _check_room_clear() -> void:
	var was_cleared: bool = room_is_cleared
	room_is_cleared = _flow.room_cleared(enemies_spawned, room_is_cleared)
	if room_is_cleared and not was_cleared:
		_on_room_cleared()

func _spawn_enemy_in_radius(min_radius: float, max_radius: float) -> Node:
	return _spawn_enemy_at_offset(_get_spawn_offset(min_radius, max_radius))

func _pick_enemy_data() -> EnemyData:
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

	if GameManager.current_room:
		DifficultyScaler.scale_enemy(enemy, GameManager.current_room.tier)

	return enemy

func _get_spawn_offset(min_radius: float, max_radius: float) -> Vector2:
	var angle: float = randf() * TAU
	var radius: float = randf_range(min_radius, max_radius)
	return Vector2(cos(angle), sin(angle) * 0.5) * radius

func _pick_room_palette() -> void:
	floor_theme = _floor_renderer.resolve_theme(floor_theme, _theme_set_by_subclass)
	_palette = _floor_renderer.get_palette(floor_theme)
