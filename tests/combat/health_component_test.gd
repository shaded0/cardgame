extends "res://tests/support/test_case.gd"

const Factory = preload("res://tests/support/test_factory.gd")

func test_heal_caps_at_max_health() -> void:
	var player := Factory.make_player(root, false)
	var health = Factory.add_health(player, 100.0, 60.0)

	var updates: Array[Array] = []
	health.health_changed.connect(func(current: float, maximum: float) -> void:
		updates.append([current, maximum])
	)

	health.heal(75.0)

	assert_eq(health.current_health, 100.0, "Healing should stop at max health.")
	assert_eq(updates.size(), 1, "Healing should emit one health_changed event.")
	assert_eq(updates[0][0], 100.0, "The emitted current health should match the capped value.")
	assert_eq(updates[0][1], 100.0, "The emitted max health should remain unchanged.")

func test_take_damage_clamps_to_zero_and_emits_died() -> void:
	var player := Factory.make_player(root, false)
	var health = Factory.add_health(player, 50.0)

	var updates: Array[Array] = []
	var died_count := 0
	health.health_changed.connect(func(current: float, maximum: float) -> void:
		updates.append([current, maximum])
	)
	health.died.connect(func() -> void:
		died_count += 1
	)

	health.take_damage(75.0)

	assert_eq(health.current_health, 0.0, "Damage should not drive health negative.")
	assert_eq(updates.size(), 1, "Damage should emit one health_changed event.")
	assert_eq(updates[0][0], 0.0, "The emitted health value should be clamped to zero.")
	assert_eq(died_count, 1, "Crossing zero health should emit died exactly once.")

func test_health_changed_reports_hp_not_effective_health_when_shielded() -> void:
	var player := Factory.make_player(root, false)
	var health = Factory.add_health(player, 100.0, 60.0)

	var updates: Array[Array] = []
	health.health_changed.connect(func(current: float, maximum: float) -> void:
		updates.append([current, maximum])
	)

	health.add_shield(25.0)

	assert_eq(health.current_health, 60.0, "Adding shield should not change current HP.")
	assert_eq(health.shield_health, 25.0, "Shield should be tracked separately from HP.")
	assert_eq(updates.size(), 1, "Adding shield should still notify listeners once.")
	assert_eq(updates[0][0], 60.0, "Health listeners should receive actual HP, not HP plus shield.")
	assert_eq(updates[0][1], 100.0, "Health listeners should receive base max HP, not shield-augmented max.")
	assert_eq(health.get_effective_health(), 85.0, "Effective health should still include active shield.")
	assert_eq(health.get_effective_max_health(), 125.0, "Effective max health should include active shield.")

func test_repeated_overkill_emits_died_only_once() -> void:
	var player := Factory.make_player(root, false)
	var health = Factory.add_health(player, 30.0, 10.0)

	var died_count := 0
	health.died.connect(func() -> void:
		died_count += 1
	)

	health.take_damage(15.0)
	health.take_damage(999.0)

	assert_eq(health.current_health, 0.0, "Overkill should still clamp HP to zero.")
	assert_eq(died_count, 1, "Death should only emit once even if more damage arrives after HP hits zero.")

func test_heal_ignores_non_positive_amounts_and_revives_death_latch() -> void:
	var player := Factory.make_player(root, false)
	var health = Factory.add_health(player, 40.0, 5.0)

	var died_count := 0
	health.died.connect(func() -> void:
		died_count += 1
	)

	health.take_damage(10.0)
	health.heal(-3.0)
	health.heal(0.0)
	health.heal(12.0)
	health.take_damage(20.0)

	assert_eq(health.current_health, 0.0, "Revived health should still clamp back to zero after lethal damage.")
	assert_eq(died_count, 2, "Healing above zero should clear the dead latch so later lethal damage emits died again.")
