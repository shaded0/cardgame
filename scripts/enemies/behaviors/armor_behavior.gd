class_name ArmorBehavior
extends Node

## Iron Beetle armor: passive 30% damage reduction, disabled when VULNERABLE.

var base_reduction: float = 0.3

func get_damage_reduction() -> float:
	var enemy = get_parent()
	if enemy == null or not is_instance_valid(enemy):
		return base_reduction

	# VULNERABLE debuff disables armor entirely
	if enemy.debuff_system and enemy.debuff_system is DebuffSystem:
		if enemy.debuff_system.has_debuff_type(Debuff.Type.VULNERABLE):
			return 0.0

	return base_reduction
