class_name Debuff
extends RefCounted

## Data for a single active debuff on an enemy.
## Mirrors the Buff class pattern for symmetry.

enum Type {
	VULNERABLE,  ## Takes 50% more damage
	WEAK,        ## Deals 25% less damage
}

var type: Type
var duration: float
var remaining: float

static func create(p_type: Type, p_duration: float) -> Debuff:
	var d := Debuff.new()
	d.type = p_type
	d.duration = p_duration
	d.remaining = p_duration
	return d
