extends "res://tests/support/test_case.gd"

const StatusEffectManagerScript = preload("res://scripts/combat/status_effect_manager.gd")
const BuffSystemScript = preload("res://scripts/combat/buff_system.gd")

class SpeedHost:
	extends CharacterBody2D

	var base_move_speed: float = 100.0
	var move_speed: float = 100.0
	var dodge_speed: float = 240.0
	var dodge_cooldown: float = 0.8

func test_slow_composes_with_active_speed_buffs_and_restores_buffed_speed_on_expiry() -> void:
	var host := SpeedHost.new()
	host.name = "SpeedHost"
	var buff_system: BuffSystem = BuffSystemScript.new()
	buff_system.name = "BuffSystem"
	host.add_child(buff_system)
	var status_manager: StatusEffectManager = StatusEffectManagerScript.new()
	status_manager.name = "StatusEffectManager"
	host.add_child(status_manager)
	root.add_child(host)

	buff_system.add_buff(Buff.create(Buff.Type.SPEED_UP, 50.0, 5.0))
	status_manager.apply_effect(StatusEffect.slow(0.4, 0.1))

	assert_near(host.move_speed, 90.0, 0.001, "Slow effects should apply on top of active speed buffs instead of resetting the actor back to base speed.")

	status_manager._process(0.2)

	assert_near(host.move_speed, 150.0, 0.001, "When slow expires, the actor should return to the currently buffed speed rather than the unbuffed baseline.")

func test_freeze_expiry_restores_current_buffed_speed() -> void:
	var host := SpeedHost.new()
	host.name = "SpeedHost"
	var buff_system: BuffSystem = BuffSystemScript.new()
	buff_system.name = "BuffSystem"
	host.add_child(buff_system)
	var status_manager: StatusEffectManager = StatusEffectManagerScript.new()
	status_manager.name = "StatusEffectManager"
	host.add_child(status_manager)
	root.add_child(host)

	buff_system.add_buff(Buff.create(Buff.Type.SPEED_UP, 30.0, 5.0))
	status_manager.apply_effect(StatusEffect.freeze(0.1))

	assert_eq(host.move_speed, 0.0, "Freeze should still override movement speed while active.")

	status_manager._process(0.2)

	assert_near(host.move_speed, 130.0, 0.001, "When freeze expires, movement speed should restore to the active buffed value instead of dropping to the base stat.")

func test_reapplying_slower_weaker_slow_does_not_shorten_or_nerf_existing_slow() -> void:
	var host := SpeedHost.new()
	host.name = "SpeedHost"
	var status_manager: StatusEffectManager = StatusEffectManagerScript.new()
	status_manager.name = "StatusEffectManager"
	host.add_child(status_manager)
	root.add_child(host)

	status_manager.apply_effect(StatusEffect.slow(0.6, 2.0))
	status_manager._process(0.5)
	status_manager.apply_effect(StatusEffect.slow(0.2, 0.5))

	assert_near(host.move_speed, 40.0, 0.001, "Reapplying a weaker slow should not reduce the active slow strength.")
	assert_true(status_manager.has_effect(StatusEffect.Type.SLOW), "Weaker reapplications should not shorten a longer active slow into early expiry.")

	status_manager._process(1.0)

	assert_true(status_manager.has_effect(StatusEffect.Type.SLOW), "A shorter reapplication should not cut down the original slow duration.")

func test_reapplying_weaker_burn_does_not_shorten_existing_burn() -> void:
	var host := SpeedHost.new()
	host.name = "BurnHost"
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	host.add_child(health)
	var status_manager: StatusEffectManager = StatusEffectManagerScript.new()
	status_manager.name = "StatusEffectManager"
	host.add_child(status_manager)
	root.add_child(host)

	status_manager.apply_effect(StatusEffect.burn(5.0, 2.0))
	status_manager._process(0.5)
	status_manager.apply_effect(StatusEffect.burn(1.0, 0.5))
	status_manager._process(1.0)

	assert_true(status_manager.has_effect(StatusEffect.Type.BURN), "Reapplying a weaker burn should not shorten the stronger existing burn duration.")
