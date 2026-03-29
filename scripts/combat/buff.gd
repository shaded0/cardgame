class_name Buff
extends RefCounted

## Data for a single active buff.
## Use `create()` to build immutable-like instances with runtime duration.

enum Type {
	DAMAGE_UP,     ## Flat bonus damage on basic attacks
	SPEED_UP,      ## Move speed increase
	DEFENSE_UP,    ## Percentage damage reduction
	EMPOWER_NEXT,  ## Next N attacks deal bonus damage, then expires
	DODGE_BOOST,   ## Faster dodge, shorter cooldown
}

var type: Type
var value: float       ## Effect magnitude (damage amount, speed bonus, % reduction)
var duration: float    ## Total duration in seconds (0 = permanent until stacks used)
var remaining: float   ## Time left
var stacks: int = 1    ## For EMPOWER_NEXT: number of empowered attacks

static func create(p_type: Type, p_value: float, p_duration: float, p_stacks: int = 1) -> Buff:
	# Builder-style constructor for cleaner effect definitions in code.
	var b := Buff.new()
	b.type = p_type
	b.value = p_value
	b.duration = p_duration
	b.remaining = p_duration
	b.stacks = p_stacks
	return b
