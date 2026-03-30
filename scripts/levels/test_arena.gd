extends "res://scripts/levels/arena_base.gd"

## Test arena setup script.
## Draws a debug isometric-style floor and handles simple timed enemy spawning bounds.

var spawn_timer: float = 3.5
var max_enemies: int = 6
var spawn_radius_min: float = 400.0
var spawn_radius_max: float = 700.0
var time_since_spawn: float = 1.0

func _ready() -> void:
	spawn_initial_wave = false
	restore_carried_health = false
	room_clear_enabled = false
	super._ready()
	_spawn_random_grass(8)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	# Spawn timer is tracked in physics time so spawn rhythm is stable.
	time_since_spawn -= delta
	if time_since_spawn <= 0.0:
		time_since_spawn = spawn_timer
		_try_spawn()

func _try_spawn() -> void:
	var current_enemies: Array[Node] = GameManager.get_enemies()
	if current_enemies.size() >= max_enemies:
		return

	_spawn_enemy_in_radius(spawn_radius_min, spawn_radius_max)
