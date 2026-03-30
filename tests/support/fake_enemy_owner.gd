extends CharacterBody2D

enum State { ALIVE, DEAD }

var current_state: int = State.ALIVE
var spawn_log: Array[Dictionary] = []

func spawn_minion(enemy_data, offset: Vector2) -> void:
	spawn_log.append({
		"enemy_data": enemy_data,
		"offset": offset,
	})
