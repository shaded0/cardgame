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
