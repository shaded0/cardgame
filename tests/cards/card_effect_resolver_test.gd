extends "res://tests/support/test_case.gd"

const Factory = preload("res://tests/support/test_factory.gd")

func test_damage_effect_targets_the_nearest_enemy() -> void:
	var player := Factory.make_player(root)
	player.global_position = Vector2.ZERO
	Factory.add_health(player, 100.0, 100.0)
	Factory.add_mana(player, 100.0, 0.0)
	var card_manager = Factory.add_card_manager(player)
	var resolver = Factory.add_card_resolver(card_manager)

	var close_enemy := Factory.make_enemy(root, Vector2(12, 0), 40.0)
	var far_enemy := Factory.make_enemy(root, Vector2(120, 0), 40.0)
	var close_health = close_enemy.get_node("HealthComponent")
	var far_health = far_enemy.get_node("HealthComponent")

	var effect = Factory.make_effect(CardEffect.EffectType.DAMAGE, 15.0, CardEffect.TargetMode.NEAREST_ENEMY)
	resolver.resolve_effect(effect)

	assert_eq(close_health.current_health, 25.0, "Damage effects should hit the nearest enemy by default.")
	assert_eq(far_health.current_health, 40.0, "Non-targeted enemies should not be damaged.")

func test_heal_and_mana_generation_effects_update_player_resources() -> void:
	var player := Factory.make_player(root)
	Factory.add_health(player, 100.0, 45.0)
	Factory.add_mana(player, 60.0, 10.0)
	var card_manager = Factory.add_card_manager(player)
	var resolver = Factory.add_card_resolver(card_manager)

	var heal = Factory.make_effect(CardEffect.EffectType.HEAL, 30.0, CardEffect.TargetMode.SELF)
	var mana_gain = Factory.make_effect(CardEffect.EffectType.MANA_GEN, 18.0, CardEffect.TargetMode.SELF)

	resolver.resolve_effect(heal)
	resolver.resolve_effect(mana_gain)

	assert_eq(player.get_node("HealthComponent").current_health, 75.0, "Heal effects should restore player health.")
	assert_eq(player.get_node("ManaComponent").current_mana, 28.0, "Mana generation effects should add mana through ManaComponent.")
