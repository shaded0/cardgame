extends "res://tests/support/test_case.gd"

const Factory = preload("res://tests/support/test_factory.gd")

func test_defense_buff_caps_damage_reduction_at_eighty_percent() -> void:
	var player := Factory.make_player(root, false)
	var buff_system = Factory.add_buff_system(player)

	buff_system.add_buff(Buff.create(Buff.Type.DEFENSE_UP, 50.0, 5.0))
	buff_system.add_buff(Buff.create(Buff.Type.DEFENSE_UP, 50.0, 5.0))

	assert_near(buff_system.damage_reduction, 0.8, 0.001, "Damage reduction should cap at 80 percent.")
	assert_near(buff_system.get_damage_after_reduction(100.0), 20.0, 0.001, "Incoming damage should use the capped reduction.")

func test_empower_buff_only_applies_to_configured_number_of_hits() -> void:
	var player := Factory.make_player(root, false)
	var buff_system = Factory.add_buff_system(player)

	buff_system.add_buff(Buff.create(Buff.Type.EMPOWER_NEXT, 12.0, 0.0, 2))

	assert_eq(buff_system.get_modified_damage(8.0), 20.0, "The first empowered attack should gain the bonus damage.")
	assert_eq(buff_system.get_modified_damage(8.0), 20.0, "The second empowered attack should still gain the bonus damage.")
	assert_eq(buff_system.get_modified_damage(8.0), 8.0, "Further attacks should fall back to base damage once stacks are consumed.")
	assert_false(buff_system.has_buff_type(Buff.Type.EMPOWER_NEXT), "Fully consumed empower buffs should clear from the active list instead of lingering forever.")

func test_speed_buff_updates_player_speed_and_reverts_on_removal() -> void:
	var player := Factory.make_player(root, false)
	player.move_speed = 120.0
	var buff_system = Factory.add_buff_system(player)
	var speed_buff := Buff.create(Buff.Type.SPEED_UP, 35.0, 2.0)

	buff_system.add_buff(speed_buff)

	assert_eq(player.move_speed, 155.0, "Speed buffs should immediately affect player.move_speed.")
	assert_true(buff_system.has_buff_type(Buff.Type.SPEED_UP), "The buff should be tracked as active.")

	buff_system.remove_buff(speed_buff)

	assert_eq(player.move_speed, 120.0, "Removing a speed buff should restore the original move speed.")
	assert_false(buff_system.has_buff_type(Buff.Type.SPEED_UP), "Removed buffs should no longer be reported as active.")

func test_defense_buff_removal_recomputes_correct_value_after_cap() -> void:
	var player := Factory.make_player(root, false)
	var buff_system = Factory.add_buff_system(player)
	var first := Buff.create(Buff.Type.DEFENSE_UP, 50.0, 5.0)
	var second := Buff.create(Buff.Type.DEFENSE_UP, 50.0, 5.0)

	buff_system.add_buff(first)
	buff_system.add_buff(second)
	buff_system.remove_buff(second)

	assert_near(buff_system.damage_reduction, 0.5, 0.001, "Removing one capped defense buff should leave the remaining reduction intact instead of undercounting it.")
	assert_near(buff_system.get_damage_after_reduction(100.0), 50.0, 0.001, "Post-removal incoming damage should use the remaining defense buff value.")

func test_timed_empower_expiry_clears_remaining_stacks_and_bonus() -> void:
	var player := Factory.make_player(root, false)
	var buff_system = Factory.add_buff_system(player)

	buff_system.add_buff(Buff.create(Buff.Type.EMPOWER_NEXT, 15.0, 0.1, 3))
	buff_system._process(0.2)

	assert_eq(buff_system.empowered_attacks, 0, "Expired timed empower buffs should not leave attack stacks behind.")
	assert_eq(buff_system.empower_bonus, 0.0, "Expired timed empower buffs should clear their bonus damage.")
	assert_false(buff_system.has_buff_type(Buff.Type.EMPOWER_NEXT), "Expired timed empower buffs should no longer be reported as active.")
