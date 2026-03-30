extends "res://tests/support/test_case.gd"

const Factory = preload("res://tests/support/test_factory.gd")

func test_permanent_debuffs_do_not_expire_when_duration_is_zero() -> void:
	var enemy := Factory.make_player(root, false)
	var debuff_system = Factory.add_debuff_system(enemy)

	debuff_system.add_debuff(Debuff.create(Debuff.Type.VULNERABLE, 0.0))
	debuff_system._process(0.5)

	assert_true(debuff_system.has_debuff_type(Debuff.Type.VULNERABLE), "Duration-zero debuffs should persist until explicitly removed.")
	assert_eq(debuff_system.get_damage_multiplier(), 1.5, "Permanent vulnerable should keep affecting incoming damage.")

func test_timed_debuffs_still_expire_normally() -> void:
	var enemy := Factory.make_player(root, false)
	var debuff_system = Factory.add_debuff_system(enemy)

	debuff_system.add_debuff(Debuff.create(Debuff.Type.WEAK, 0.1))
	debuff_system._process(0.2)

	assert_false(debuff_system.has_debuff_type(Debuff.Type.WEAK), "Timed debuffs should still expire once their duration elapses.")
	assert_eq(debuff_system.get_attack_multiplier(), 1.0, "Expired weak should no longer reduce outgoing damage.")
