class_name StatusEffect
extends RefCounted

## Data class for a status effect instance.
## StatusEffectManager ticks these over time.

enum Type { BURN, SLOW, POISON, FREEZE }

## Type of damage-over-time / control effect.
var type: Type = Type.BURN
## Damage applied each tick (for burn/poison variants).
var damage_per_tick: float = 0.0
## Tick interval for periodic damage/status pulses.
var tick_interval: float = 1.0
## Total status lifetime in seconds.
var duration: float = 3.0
## Countdown updated by `StatusEffectManager`.
var remaining: float = 3.0
## Slow multiplier applied to movement speed while active.
var slow_percent: float = 0.0
## Number of stacked stacks for refreshable status systems.
var stacks: int = 1
## Tracks when next tick should fire.
var _tick_timer: float = 0.0

## Generic constructor for all typed status effects.
## Defaults are tuned for simple one-shot creation from callers.
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

static func burn(damage: float = 3.0, effect_duration: float = 4.0) -> StatusEffect:
	# Damage over time; tick cadence stays fast for perceived burn persistence.
	return create(Type.BURN, damage, effect_duration, 0.0, 0.5)

static func slow(percent: float = 0.4, effect_duration: float = 3.0) -> StatusEffect:
	# Percentage-based slow with no direct damage.
	return create(Type.SLOW, 0.0, effect_duration, percent)

static func poison(damage: float = 2.0, effect_duration: float = 6.0) -> StatusEffect:
	# Slower tick cadence to make poison visually feel distinct from burn.
	return create(Type.POISON, damage, effect_duration, 0.0, 1.0)

static func freeze(effect_duration: float = 1.5) -> StatusEffect:
	# Full crowd-control window used for positioning and punish windows.
	return create(Type.FREEZE, 0.0, effect_duration, 1.0)
