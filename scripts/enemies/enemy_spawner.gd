extends Node2D

## Generic timed spawner for enemies.
## This node only decides "when" and "where" to spawn; enemy behavior stays in BaseEnemy.

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 3.0
@export var max_enemies: int = 8
@export var spawn_radius: float = 150.0

var spawn_timer: float = 0.0

func _ready() -> void:
	# Start with half delay so early gameplay starts with action right away.
	spawn_timer = spawn_interval * 0.5  # First spawn comes quicker

func _physics_process(delta: float) -> void:
	# Use _physics_process for deterministic timing independent of frame rate.
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = spawn_interval
		_try_spawn()

func _try_spawn() -> void:
	# Respect a hard cap so arena doesn't get overwhelmed.
	var current_enemies: Array[Node] = GameManager.get_enemies()
	if current_enemies.size() >= max_enemies:
		return

	if enemy_scene == null:
		return

	var enemy: Node2D = enemy_scene.instantiate() as Node2D
	if enemy == null:
		return

	# Random position around spawner
	var angle: float = randf() * TAU
	var offset: Vector2 = Vector2(cos(angle), sin(angle) * 0.5) * spawn_radius
	enemy.global_position = global_position + offset

	var parent: Node = get_parent()
	if parent == null:
		return
	parent.add_child(enemy)
