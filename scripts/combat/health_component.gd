class_name HealthComponent
extends Node

## Shared health component used by player/enemies.
## Emits `health_changed` and `died` signals for UI and death handling.

signal health_changed(current: float, maximum: float)
signal died

@export var max_health: float = 100.0
var current_health: float

func _ready() -> void:
	# Always start at full health unless designer overrides after assigning `max_health`.
	current_health = max_health

func take_damage(amount: float) -> void:
	# Clamp to 0 to avoid negative HP and keep UI simple.
	current_health = max(current_health - amount, 0.0)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		died.emit()

func heal(amount: float) -> void:
	# Clamp to max_health, then notify UI.
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)
