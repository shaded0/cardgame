class_name DifficultyScaler
extends RefCounted

## Applies tier-based stat scaling to enemies after they spawn.
## Higher tiers produce tougher enemies with more HP, damage, and speed.

static func scale_enemy(enemy: Node, tier: int) -> void:
	if tier <= 0:
		return

	var hp_mult: float = 1.0 + tier * 0.2
	var dmg_mult: float = 1.0 + tier * 0.15
	var spd_mult: float = 1.0 + tier * 0.05

	# Scale runtime stats (already copied from EnemyData in _ready)
	enemy.move_speed *= spd_mult
	enemy.attack_damage *= dmg_mult

	# Scale health component
	var health: HealthComponent = enemy.get_node_or_null("HealthComponent")
	if health:
		health.max_health *= hp_mult
		health.reset_to_full()

	# Scale hitbox damage
	var hitbox: Hitbox = enemy.get_node_or_null("Hitbox")
	if hitbox:
		hitbox.damage = enemy.attack_damage
