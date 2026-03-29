extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 3.0
@export var max_enemies: int = 8
@export var spawn_radius: float = 150.0

var spawn_timer: float = 0.0

func _ready() -> void:
	spawn_timer = spawn_interval * 0.5  # First spawn comes quicker

func _physics_process(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = spawn_interval
		_try_spawn()

func _try_spawn() -> void:
	var current_enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	if current_enemies.size() >= max_enemies:
		return

	if enemy_scene == null:
		return

	var enemy: Node = enemy_scene.instantiate()

	# Random position around spawner
	var angle: float = randf() * TAU
	var offset: Vector2 = Vector2(cos(angle), sin(angle) * 0.5) * spawn_radius
	enemy.global_position = global_position + offset

	get_parent().add_child(enemy)
