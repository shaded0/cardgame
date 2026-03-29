class_name HealthComponent
extends Node

## Shared health component used by player/enemies.
## Emits `health_changed` and `died` signals for UI and death handling.

signal health_changed(current: float, maximum: float)
signal died

@export var max_health: float = 100.0
var current_health: float
var shield_health: float = 0.0
var _is_dead: bool = false

func _ready() -> void:
	# Always start at full health unless designer overrides after assigning `max_health`.
	reset_to_full()

func take_damage(amount: float) -> void:
	# Spend temporary shield first, then apply any remainder to health.
	var remaining_damage: float = max(amount, 0.0)
	if remaining_damage <= 0.0:
		return

	if shield_health > 0.0 and remaining_damage > 0.0:
		var absorbed: float = min(shield_health, remaining_damage)
		shield_health -= absorbed
		remaining_damage -= absorbed

	if remaining_damage > 0.0:
		current_health = max(current_health - remaining_damage, 0.0)

	_emit_health_changed()
	if current_health <= 0.0 and not _is_dead:
		_is_dead = true
		died.emit()

func heal(amount: float) -> void:
	# Clamp to max_health, then notify UI.
	current_health = min(current_health + amount, max_health)
	_emit_health_changed()

func add_shield(amount: float) -> void:
	# Shield extends effective survivability without permanently raising max health.
	shield_health = max(shield_health + amount, 0.0)
	_emit_health_changed()

func set_current_health(value: float) -> void:
	current_health = clampf(value, 0.0, max_health)
	_is_dead = current_health <= 0.0
	_emit_health_changed()

func reset_to_full() -> void:
	current_health = max_health
	shield_health = 0.0
	_is_dead = false
	_emit_health_changed()

func _emit_health_changed() -> void:
	health_changed.emit(current_health, max_health)

func get_effective_health() -> float:
	return current_health + shield_health

func get_effective_max_health() -> float:
	return max_health + shield_health
