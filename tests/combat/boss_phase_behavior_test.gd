extends "res://tests/support/test_case.gd"

const Factory = preload("res://tests/support/test_factory.gd")
const FakeEnemyOwnerScript = preload("res://tests/support/fake_enemy_owner.gd")
const BossPhaseBehaviorScript = preload("res://scripts/enemies/behaviors/boss_phase.gd")

func test_boss_phase_connects_health_listener_only_once() -> void:
	var enemy: CharacterBody2D = FakeEnemyOwnerScript.new()
	enemy.name = "Boss"
	root.add_child(enemy)
	var health: HealthComponent = Factory.add_health(enemy, 100.0, 100.0)

	var behavior: BossPhaseBehavior = BossPhaseBehaviorScript.new()
	enemy.add_child(behavior)
	await tree.process_frame

	var callback := Callable(behavior, "_on_health_changed")
	assert_true(health.health_changed.is_connected(callback), "Boss phase behavior should listen for boss health changes while active.")

	behavior._ready()
	await tree.process_frame

	assert_true(health.health_changed.is_connected(callback), "Repeated setup should keep a single health_changed hookup instead of duplicating it.")

func test_boss_phase_disconnects_health_listener_on_exit() -> void:
	var enemy: CharacterBody2D = FakeEnemyOwnerScript.new()
	enemy.name = "Boss"
	root.add_child(enemy)
	var health: HealthComponent = Factory.add_health(enemy, 100.0, 100.0)

	var behavior: BossPhaseBehavior = BossPhaseBehaviorScript.new()
	enemy.add_child(behavior)
	await tree.process_frame

	var callback := Callable(behavior, "_on_health_changed")
	behavior.queue_free()
	root.propagate_notification(Node.NOTIFICATION_EXIT_TREE)

	assert_false(health.health_changed.is_connected(callback), "Boss phase behavior should disconnect from health_changed when freed.")

func test_boss_phase_enrage_happens_only_once() -> void:
	var enemy: CharacterBody2D = FakeEnemyOwnerScript.new()
	enemy.name = "Boss"
	root.add_child(enemy)

	var behavior: BossPhaseBehavior = BossPhaseBehaviorScript.new()
	enemy.add_child(behavior)

	behavior._on_health_changed(40.0, 100.0)
	var move_speed_after_first: float = enemy.move_speed
	var damage_after_first: float = enemy.attack_damage
	behavior._on_health_changed(20.0, 100.0)

	assert_eq(behavior.phase, 2, "Boss should enter phase 2 once health drops below the enrage threshold.")
	assert_eq(enemy.move_speed, move_speed_after_first, "Boss enrage should not keep multiplying move speed on later low-health updates.")
	assert_eq(enemy.attack_damage, damage_after_first, "Boss enrage should not keep multiplying attack damage on later low-health updates.")
