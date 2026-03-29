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
