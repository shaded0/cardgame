class_name SynergyChecker
extends RefCounted

## Checks whether a card in hand synergizes with the current combat state.
## Called by HUD after a card is played to highlight synergistic follow-ups.

static func check_synergy(card: CardData, player: CharacterBody2D) -> bool:
	if card == null or player == null:
		return false

	var buff_sys: BuffSystem = player.get_node_or_null("BuffSystem")
	var health_comp: HealthComponent = player.get_node_or_null("HealthComponent")

	for effect in card.effects:
		if _check_effect_synergy(effect, buff_sys, health_comp):
			return true
	return false

static func _check_effect_synergy(
	effect: CardEffect,
	buff_sys: BuffSystem,
	health_comp: HealthComponent
) -> bool:
	var is_damage_effect: bool = effect.type in [
		CardEffect.EffectType.DAMAGE,
		CardEffect.EffectType.AOE,
		CardEffect.EffectType.MULTI_HIT,
		CardEffect.EffectType.PROJECTILE,
	]
	var is_defensive_effect: bool = effect.type in [
		CardEffect.EffectType.HEAL,
		CardEffect.EffectType.SHIELD,
	]

	# Damage cards synergize when enemies are vulnerable
	if is_damage_effect and _any_enemy_has_debuff(Debuff.Type.VULNERABLE):
		return true

	# Damage cards synergize with player damage buffs
	if is_damage_effect and buff_sys:
		if buff_sys.has_buff_type(Buff.Type.DAMAGE_UP):
			return true
		if buff_sys.has_buff_type(Buff.Type.EMPOWER_NEXT):
			return true

	# Heal/shield cards synergize when health is low
	if is_defensive_effect and health_comp:
		if health_comp.max_health > 0.0:
			var health_pct: float = health_comp.current_health / health_comp.max_health
			if health_pct < 0.4:
				return true

	return false

static func _any_enemy_has_debuff(debuff_type: Debuff.Type) -> bool:
	var enemies: Array[Node] = GameManager.get_enemies()
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var debuff_sys: DebuffSystem = enemy.get_node_or_null("DebuffSystem") as DebuffSystem
		if debuff_sys and debuff_sys.has_debuff_type(debuff_type):
			return true
	return false
