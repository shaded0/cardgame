extends "res://tests/support/test_case.gd"

const Factory = preload("res://tests/support/test_factory.gd")

func test_add_mana_clamps_to_maximum_and_emits_signal() -> void:
	var player := Factory.make_player(root)
	var mana = Factory.add_mana(player, 40.0, 10.0)

	var updates: Array[Array] = []
	mana.mana_changed.connect(func(current: float, maximum: float) -> void:
		updates.append([current, maximum])
	)

	mana.add_mana(50.0)

	assert_eq(mana.current_mana, 40.0, "Mana gains should clamp to max_mana.")
	assert_eq(updates.size(), 1, "Mana gain should emit a single mana_changed event.")
	assert_eq(updates[0][0], 40.0, "The emitted current mana should reflect the clamped value.")
	assert_eq(updates[0][1], 40.0, "The emitted max mana should remain unchanged.")

func test_on_basic_attack_hit_uses_configured_reward() -> void:
	var player := Factory.make_player(root)
	var mana = Factory.add_mana(player, 100.0, 5.0)
	mana.mana_per_hit_dealt = 12.0

	mana.on_basic_attack_hit()

	assert_eq(mana.current_mana, 17.0, "Basic attack hits should grant mana_per_hit_dealt.")

func test_spend_mana_rejects_expensive_actions() -> void:
	var player := Factory.make_player(root)
	var mana = Factory.add_mana(player, 25.0, 10.0)

	var update_count := 0
	mana.mana_changed.connect(func(_current: float, _maximum: float) -> void:
		update_count += 1
	)

	var spent := mana.spend_mana(15.0)

	assert_false(spent, "Spending more mana than available should fail.")
	assert_eq(mana.current_mana, 10.0, "Failed spends should leave current mana untouched.")
	assert_eq(update_count, 0, "Failed spends should not emit mana_changed.")
