class_name StatusEffect
extends RefCounted

## Data class for a status effect instance.
## StatusEffectManager ticks these over time.

enum Type { BURN, SLOW, POISON, FREEZE }

var type: Type = Type.BURN
var damage_per_tick: float = 0.0
var tick_interval: float = 1.0
var duration: float = 3.0
var remaining: float = 3.0
var slow_percent: float = 0.0
var stacks: int = 1
var _tick_timer: float = 0.0

static func create(p_type: Type, p_damage: float = 0.0, p_duration: float = 3.0, p_slow: float = 0.0, p_tick_interval: float = 1.0) -> StatusEffect:
	var effect := StatusEffect.new()
	effect.type = p_type
	effect.damage_per_tick = p_damage
	effect.duration = p_duration
	effect.remaining = p_duration
	effect.slow_percent = p_slow
	effect.tick_interval = p_tick_interval
	effect._tick_timer = p_tick_interval
	return effect

static func burn(damage: float = 3.0, duration: float = 4.0) -> StatusEffect:
	return create(Type.BURN, damage, duration, 0.0, 0.5)

static func slow(percent: float = 0.4, duration: float = 3.0) -> StatusEffect:
	return create(Type.SLOW, 0.0, duration, percent)

static func poison(damage: float = 2.0, duration: float = 6.0) -> StatusEffect:
	return create(Type.POISON, damage, duration, 0.0, 1.0)

static func freeze(duration: float = 1.5) -> StatusEffect:
	return create(Type.FREEZE, 0.0, duration, 1.0)
