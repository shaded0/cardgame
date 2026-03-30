extends CharacterBody2D

enum State { ALIVE, DEAD }

var current_state: int = State.ALIVE
var move_speed: float = 100.0
var attack_damage: float = 10.0
var spawn_log: Array[Dictionary] = []

func spawn_minion(enemy_data, offset: Vector2) -> void:
	spawn_log.append({
		"enemy_data": enemy_data,
		"offset": offset,
	})
