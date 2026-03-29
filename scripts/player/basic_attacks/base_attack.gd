class_name BaseAttack
extends Node

## Base class for class-specific basic attacks.
## Concrete classes override execute/end_attack and optionally attack duration.

func execute(_player: PlayerController, _direction: Vector2) -> void:
	pass

func end_attack(_player: PlayerController) -> void:
	pass

func get_attack_duration() -> float:
	return 0.3
