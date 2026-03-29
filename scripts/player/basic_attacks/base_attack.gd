class_name BaseAttack
extends Node

## Base class for class-specific basic attacks.
## Concrete classes override execute/end_attack and optionally attack duration.

## Execute a class-specific attack.
## `_direction` is in world-space relative to player orientation.
func execute(_player: PlayerController, _direction: Vector2) -> void:
	pass

## End/cleanup attack state (cancel hitboxes, stop VFX, etc.).
func end_attack(_player: PlayerController) -> void:
	pass

## Returns default duration for fallback/timeout logic.
## Concrete scripts should override when their animation timing differs.
func get_attack_duration() -> float:
	return 0.3
