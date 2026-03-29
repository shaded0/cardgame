class_name Debuff
extends RefCounted

## Data for a single active debuff on an enemy.
## Mirrors the Buff class pattern for symmetry.

enum Type {
	VULNERABLE,  ## Takes 50% more damage
	WEAK,        ## Deals 25% less damage
	FREEZE,      ## Completely stops movement and attacks — cards create safe windows
}

## Debuff kind applied by card/enemy effects and consumed by `DebuffSystem`.
var type: Type
## Full configured duration in seconds when the debuff is applied.
var duration: float
## Time left before automatic expiration.
var remaining: float

## Factory constructor keeps debuff construction in one place and initializes countdown.
static func create(p_type: Type, p_duration: float) -> Debuff:
	var d := Debuff.new()
	d.type = p_type
	d.duration = p_duration
	d.remaining = p_duration
	return d
