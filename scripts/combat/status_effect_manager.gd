class_name StatusEffectManager
extends Node

## Manages active status effects on the parent entity.
## Ticks damage for BURN/POISON, applies speed reduction for SLOW,
## and freezes movement for FREEZE.

signal effect_applied(effect: StatusEffect)
signal effect_expired(effect: StatusEffect)

var active_effects: Array[StatusEffect] = []
var _base_speed: float = -1.0
var _base_modulate: Color = Color(1, 1, 1, 1)

func _ready() -> void:
	# Cache the entity's baseline presentation so effects can restore cleanly.
	var parent = get_parent()
	if parent == null:
		return
	_base_speed = _get_reference_speed(parent)
	if "modulate" in parent:
		_base_modulate = parent.modulate

func _process(delta: float) -> void:
	var parent = get_parent()
	if parent == null or not is_instance_valid(parent):
		return

	if active_effects.is_empty():
		_apply_speed_modifiers(parent)
		_apply_visual(parent)
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
	var parent = get_parent()
	if parent == null or not is_instance_valid(parent):
		return

	# POISON stacks, others refresh duration
	if effect.type == StatusEffect.Type.POISON:
		var existing := _find_effect(StatusEffect.Type.POISON)
		if existing:
			existing.stacks += 1
			existing.remaining = maxf(existing.remaining, effect.duration)
			_apply_speed_modifiers(parent)
			_apply_visual(parent)
			return
	else:
		var existing := _find_effect(effect.type)
		if existing:
			existing.remaining = effect.duration
			existing.damage_per_tick = maxf(existing.damage_per_tick, effect.damage_per_tick)
			existing.slow_percent = maxf(existing.slow_percent, effect.slow_percent)
			_apply_speed_modifiers(parent)
			_apply_visual(parent)
			return

	active_effects.append(effect)
	effect_applied.emit(effect)
	_apply_speed_modifiers(parent)
	_apply_visual(parent)

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
	if not "move_speed" in parent:
		return
	var reference_speed: float = _get_reference_speed(parent)
	if reference_speed < 0.0:
		return

	var mult := get_slow_multiplier()
	if is_frozen():
		parent.move_speed = 0.0
	else:
		parent.move_speed = reference_speed * mult

func _apply_visual(parent: Node) -> void:
	if not "modulate" in parent:
		return

	if active_effects.is_empty():
		parent.modulate = _base_modulate
		return

	# Priority: freeze (blue) > burn (orange) > poison (green) > slow (blue-grey)
	if has_effect(StatusEffect.Type.FREEZE):
		parent.modulate = _base_modulate * Color(0.5, 0.7, 1.2, 1.0)
	elif has_effect(StatusEffect.Type.BURN):
		var pulse := sin(Time.get_ticks_msec() * 0.008) * 0.15 + 0.85
		parent.modulate = _base_modulate * Color(1.2, 0.7 * pulse, 0.5, 1.0)
	elif has_effect(StatusEffect.Type.POISON):
		parent.modulate = _base_modulate * Color(0.7, 1.1, 0.6, 1.0)
	elif has_effect(StatusEffect.Type.SLOW):
		parent.modulate = _base_modulate * Color(0.7, 0.8, 1.0, 1.0)

func _get_reference_speed(parent: Node) -> float:
	var speed_bonus: float = _get_external_speed_bonus(parent)
	if "base_move_speed" in parent:
		return float(parent.base_move_speed) + speed_bonus
	if _base_speed >= 0.0:
		return _base_speed + speed_bonus
	if "move_speed" in parent:
		return float(parent.move_speed)
	return -1.0

func _get_external_speed_bonus(parent: Node) -> float:
	var buff_system: Node = parent.get_node_or_null("BuffSystem")
	if buff_system != null and "bonus_speed" in buff_system:
		return float(buff_system.bonus_speed)
	return 0.0
