class_name BaseAttack
extends Node

func execute(_player: CharacterBody2D, _direction: Vector2) -> void:
	pass

func end_attack(_player: CharacterBody2D) -> void:
	pass

func get_attack_duration() -> float:
	return 0.3
