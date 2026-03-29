extends "res://tests/support/test_case.gd"

const Factory = preload("res://tests/support/test_factory.gd")
const SoldierAttackScript = preload("res://scripts/player/basic_attacks/soldier_attack.gd")

var _previous_class_config: ClassConfig = null
var _previous_attack_logging: bool = true

func before_each() -> void:
	_previous_class_config = GameManager.current_class_config
	_previous_attack_logging = GameManager.debug_attack_logging
	GameManager.current_class_config = null
	GameManager.debug_attack_logging = false

func after_each() -> void:
	GameManager.current_class_config = _previous_class_config
	GameManager.debug_attack_logging = _previous_attack_logging

func test_watchdog_force_ends_stuck_attack_and_returns_to_idle() -> void:
	var player := Factory.make_player_controller(root)

	player.state_machine.transition_to("attack")
	player._update_attack_watchdog(player.attack_duration + 0.25)

	assert_false(player._attack_active, "Watchdog should clear the active attack flag once an attack runs too long.")
	assert_eq(player._attack_elapsed, 0.0, "Watchdog recovery should reset elapsed attack time.")
	assert_eq(player.state_machine.current_state.name.to_lower(), "idle", "Watchdog recovery should return the player to a neutral state.")
	assert_eq(player.hitbox.position, Vector2.ZERO, "Watchdog recovery should pull the melee hitbox back to the player.")
	assert_false(player.attack_visual.visible, "Watchdog recovery should hide the attack visual so future attacks look correct.")

func test_force_end_attack_consumes_buffered_retry() -> void:
	var player := Factory.make_player_controller(root)

	player.state_machine.transition_to("attack")
	player.state_machine.buffer_attack_input()
	player.force_end_attack()

	assert_eq(player.state_machine.current_state.name.to_lower(), "attack", "Buffered attack input should immediately retry after force-ending a stuck attack.")
	assert_true(player._attack_active, "Retrying from buffered input should leave the player attacking again.")
	assert_true(player.attack_visual.visible, "Retry attacks should reactivate the attack visual.")

func test_start_attack_rebuilds_missing_attack_controller() -> void:
	var config := Factory.make_class_config(SoldierAttackScript)
	var player := Factory.make_player_controller(root, config)
	var initial_attack = player.current_attack

	assert_not_null(initial_attack, "Configured players should build an attack controller on spawn.")
	initial_attack.free()

	var started := player.start_attack()

	assert_true(started, "Attack start should self-heal when the attack controller was freed unexpectedly.")
	assert_true(is_instance_valid(player.current_attack), "Attack start should rebuild a valid attack controller.")
	assert_true(player.current_attack != initial_attack, "Rebuilt controllers should replace the freed instance.")
	assert_eq(player.current_attack.get_script(), SoldierAttackScript, "Controller rebuilds should preserve the class attack script.")

func test_clear_tracked_fx_removes_only_matching_player_effects() -> void:
	var player := Factory.make_player_controller(root)
	var dodge_fx := Sprite2D.new()
	dodge_fx.set_meta("fx_owner_id", player.get_instance_id())
	dodge_fx.set_meta("fx_tag", PlayerController.DODGE_AFTERIMAGE_FX_TAG)
	root.add_child(dodge_fx)

	var other_fx := Sprite2D.new()
	other_fx.set_meta("fx_owner_id", player.get_instance_id())
	other_fx.set_meta("fx_tag", "mana_gain")
	root.add_child(other_fx)

	player.clear_tracked_fx(PlayerController.DODGE_AFTERIMAGE_FX_TAG)

	assert_true(dodge_fx.is_queued_for_deletion(), "Tracked dodge afterimages should be queued for cleanup.")
	assert_false(other_fx.is_queued_for_deletion(), "Clearing one fx tag should not remove unrelated player visuals.")

func test_force_end_attack_clears_tracked_dodge_fx_and_recovers() -> void:
	var player := Factory.make_player_controller(root)
	var dodge_fx := Sprite2D.new()
	dodge_fx.set_meta("fx_owner_id", player.get_instance_id())
	dodge_fx.set_meta("fx_tag", PlayerController.DODGE_AFTERIMAGE_FX_TAG)
	root.add_child(dodge_fx)

	player.state_machine.transition_to("attack")
	player.force_end_attack()

	assert_true(dodge_fx.is_queued_for_deletion(), "Force-ending attacks should sweep any tagged dodge afterimages.")
	assert_eq(player.state_machine.current_state.name.to_lower(), "idle", "Force-ending attacks should recover the player to a neutral state.")
	assert_false(player._attack_active, "Force-ending attacks should clear active attack state.")
