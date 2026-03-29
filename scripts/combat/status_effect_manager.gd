class_name StatusEffectManager
extends Node

## Manages active status effects on the parent entity.
## Ticks damage for BURN/POISON, applies speed reduction for SLOW,
## and freezes movement for FREEZE.

signal effect_applied(effect: StatusEffect)
signal effect_expired(effect: StatusEffect)

var active_effects: Array[StatusEffect] = []
var _base_speed: float = -1.0

func _ready() -> void:
	# Cache the entity's base speed for slow calculations
	var parent = get_parent()
	if parent and "move_speed" in parent:
		_base_speed = parent.move_speed

func _process(delta: float) -> void:
	if active_effects.is_empty():
		return

	var parent = get_parent()
	if parent == null or not is_instance_valid(parent):
		return

	var health: HealthComponent = parent.get_node_or_null("HealthComponent")
	var expired: Array[StatusEffect] = []

	for effect in active_effects:
		effect.remaining -= delta

		if effect.remaining <= 0.0:
			expired.append(effect)
			continue

		# Tick damage
		if effect.damage_per_tick > 0.0:
			effect._tick_timer -= delta
			if effect._tick_timer <= 0.0:
				effect._tick_timer = effect.tick_interval
				if health:
					var tick_damage: float = effect.damage_per_tick * effect.stacks
					health.take_damage(tick_damage)

					# Visual feedback
					var color := Color(1.0, 0.5, 0.1) if effect.type == StatusEffect.Type.BURN else Color(0.4, 0.8, 0.2)
					DamageNumber.spawn(parent.get_parent(), parent.global_position, tick_damage, color)

	# Remove expired effects
	for effect in expired:
		active_effects.erase(effect)
		effect_expired.emit(effect)

	# Recalculate speed modifiers
	_apply_speed_modifiers(parent)

	# Apply visual tint
	_apply_visual(parent)

func apply_effect(effect: StatusEffect) -> void:
	# POISON stacks, others refresh duration
	if effect.type == StatusEffect.Type.POISON:
		var existing := _find_effect(StatusEffect.Type.POISON)
		if existing:
			existing.stacks += 1
			existing.remaining = maxf(existing.remaining, effect.duration)
			return
	else:
		var existing := _find_effect(effect.type)
		if existing:
			existing.remaining = effect.duration
			existing.damage_per_tick = maxf(existing.damage_per_tick, effect.damage_per_tick)
			existing.slow_percent = maxf(existing.slow_percent, effect.slow_percent)
			return

	active_effects.append(effect)
	effect_applied.emit(effect)

func has_effect(type: StatusEffect.Type) -> bool:
	return _find_effect(type) != null

func get_slow_multiplier() -> float:
	var max_slow: float = 0.0
	for effect in active_effects:
		if effect.slow_percent > max_slow:
			max_slow = effect.slow_percent
	return 1.0 - max_slow

func is_frozen() -> bool:
	return has_effect(StatusEffect.Type.FREEZE)

func _find_effect(type: StatusEffect.Type) -> StatusEffect:
	for effect in active_effects:
		if effect.type == type:
			return effect
	return null

func _apply_speed_modifiers(parent: Node) -> void:
	if _base_speed < 0.0 or not "move_speed" in parent:
		return

	var mult := get_slow_multiplier()
	if is_frozen():
		parent.move_speed = 0.0
	else:
		parent.move_speed = _base_speed * mult

func _apply_visual(parent: Node) -> void:
	if active_effects.is_empty():
		return

	# Priority: freeze (blue) > burn (orange) > poison (green) > slow (blue-grey)
	if has_effect(StatusEffect.Type.FREEZE):
		parent.modulate = Color(0.5, 0.7, 1.2, 1.0)
	elif has_effect(StatusEffect.Type.BURN):
		var pulse := sin(Time.get_ticks_msec() * 0.008) * 0.15 + 0.85
		parent.modulate = Color(1.2, 0.7 * pulse, 0.5, 1.0)
	elif has_effect(StatusEffect.Type.POISON):
		parent.modulate = Color(0.7, 1.1, 0.6, 1.0)
	elif has_effect(StatusEffect.Type.SLOW):
		parent.modulate = Color(0.7, 0.8, 1.0, 1.0)
