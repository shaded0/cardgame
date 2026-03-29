extends "res://tests/support/test_case.gd"

const Factory = preload("res://tests/support/test_factory.gd")

func after_each() -> void:
	Engine.time_scale = 1.0

func test_initialize_deck_draws_a_full_hand_and_emits_update() -> void:
	var player := Factory.make_player(root)
	Factory.add_mana(player, 100.0, 100.0)
	var card_manager = Factory.add_card_manager(player)

	var updates: Array[Array] = []
	card_manager.hand_updated.connect(func(hand: Array) -> void:
		updates.append(hand.duplicate())
	)

	var strike = Factory.make_card("Strike")
	var heal = Factory.make_card("Heal")
	card_manager.initialize_deck([strike, heal])

	assert_eq(card_manager.hand.size(), card_manager.HAND_SIZE, "Initializing a deck should always populate the full hand.")
	assert_eq(updates.size(), 1, "Initializing a deck should emit exactly one hand update.")
	for card in card_manager.hand:
		assert_true(card == strike or card == heal, "Hand cards should come from the provided card pool.")

func test_try_play_card_spends_mana_and_replaces_chain_cards() -> void:
	var player := Factory.make_player(root)
	var mana = Factory.add_mana(player, 100.0, 35.0)
	var card_manager = Factory.add_card_manager(player)

	var finisher = Factory.make_card("Finisher")
	var starter = Factory.make_card("Starter", 10, finisher)
	card_manager.hand = [starter]

	var played_cards: Array[String] = []
	var update_count := 0
	card_manager.card_played.connect(func(card: Resource, slot_index: int) -> void:
		played_cards.append("%s@%d" % [card.card_name, slot_index])
	)
	card_manager.hand_updated.connect(func(_hand: Array) -> void:
		update_count += 1
	)

	card_manager.try_play_card(0)

	assert_eq(mana.current_mana, 25.0, "Playing a card should spend its mana cost.")
	assert_eq(card_manager.hand[0], finisher, "Chain cards should replace the played card in the same slot.")
	assert_eq(played_cards, ["Starter@0"], "Card play should emit the played card and slot index.")
	assert_eq(update_count, 1, "Playing a card should emit a new hand update.")

func test_try_play_card_stops_when_mana_is_insufficient() -> void:
	var player := Factory.make_player(root)
	var mana = Factory.add_mana(player, 100.0, 5.0)
	var card_manager = Factory.add_card_manager(player)
	var expensive = Factory.make_card("Expensive", 20)
	card_manager.hand = [expensive]

	var played_count := 0
	card_manager.card_played.connect(func(_card: Resource, _slot_index: int) -> void:
		played_count += 1
	)

	card_manager.try_play_card(0)

	assert_eq(mana.current_mana, 5.0, "Failed plays should not spend mana.")
	assert_eq(card_manager.hand[0], expensive, "Failed plays should leave the hand unchanged.")
	assert_eq(played_count, 0, "Failed plays should not emit card_played.")

func test_initialize_deck_with_no_cards_emits_empty_draw_pile_count() -> void:
	var player := Factory.make_player(root)
	Factory.add_mana(player, 100.0, 100.0)
	var card_manager = Factory.add_card_manager(player)

	var draw_counts: Array[int] = []
	card_manager.draw_pile_changed.connect(func(count: int) -> void:
		draw_counts.append(count)
	)

	card_manager.initialize_deck([])

	assert_eq(card_manager.hand.size(), 0, "Empty decks should leave the player's hand empty.")
	assert_eq(draw_counts, [0], "Empty decks should explicitly emit a zero draw pile count so the HUD stays in sync.")

func test_try_cycle_card_spends_mana_and_replaces_the_slot() -> void:
	var player := Factory.make_player(root)
	var mana = Factory.add_mana(player, 100.0, 50.0)
	var card_manager = Factory.add_card_manager(player)
	var strike = Factory.make_card("Strike")
	var defend = Factory.make_card("Defend")
	card_manager.deck = [strike, defend]
	card_manager.draw_pile = [defend]
	card_manager.hand = [strike]

	var cycle_events: Array[String] = []
	card_manager.card_cycled.connect(func(old_card: CardData, new_card: CardData, slot_index: int) -> void:
		cycle_events.append("%s>%s@%d" % [old_card.card_name, new_card.card_name, slot_index])
	)

	card_manager.try_cycle_card(0)

	assert_eq(mana.current_mana, 45.0, "Cycling should spend the configured mana cost.")
	assert_eq(card_manager.hand[0], defend, "Cycling should replace the chosen slot with the next drawn card.")
	assert_contains(card_manager.draw_pile, strike, "Cycling should return the old card to the draw pile.")
	assert_eq(cycle_events, ["Strike>Defend@0"], "Cycling should emit the swapped cards and slot index.")

func test_mana_cost_modifier_immediately_affects_card_playability() -> void:
	var player := Factory.make_player(root)
	Factory.add_mana(player, 100.0, 7.0)
	var card_manager = Factory.add_card_manager(player)
	var card = Factory.make_card("Heavy Slash", 7)

	assert_true(card_manager.can_play_card(card, 7.0), "Cards should be playable before a silence-style cost increase is applied.")

	card_manager.apply_mana_cost_modifier(2.0, 5.0)

	assert_false(card_manager.can_play_card(card, 7.0), "Temporary mana cost increases should immediately update playability checks.")

func test_zero_cost_cards_remain_playable_without_spending_mana() -> void:
	var player := Factory.make_player(root)
	var mana = Factory.add_mana(player, 100.0, 6.0)
	var card_manager = Factory.add_card_manager(player)
	var free_card = Factory.make_card("Mana Surge", 0)
	card_manager.hand = [free_card]

	var played_cards: Array[String] = []
	card_manager.card_played.connect(func(card: CardData, _slot_index: int, mana_spent: float) -> void:
		played_cards.append("%s@%.1f" % [card.card_name, mana_spent])
	)

	assert_true(card_manager.can_play_card(free_card, mana.current_mana), "Zero-cost cards should be playable without any extra resource gate.")

	card_manager.try_play_card(0)

	assert_eq(mana.current_mana, 6.0, "Zero-cost cards should not spend mana just to satisfy the shared card-play path.")
	assert_eq(played_cards, ["Mana Surge@0.0"], "Zero-cost cards should still resolve and report zero mana spent.")

func test_tactical_focus_teardown_restores_the_previous_time_scale() -> void:
	Engine.time_scale = 0.45
	var player := Factory.make_player(root)
	var card_manager: CardManager = Factory.add_card_manager(player)

	card_manager._begin_tactical_focus()
	assert_near(Engine.time_scale, card_manager.TACTICAL_TIME_SCALE, 0.001, "Entering tactical focus should apply the tactical slowdown.")

	card_manager.queue_free()
	root.propagate_notification(Node.NOTIFICATION_EXIT_TREE)

	assert_near(Engine.time_scale, 0.45, 0.001, "Destroying CardManager mid-focus should restore the pre-existing time scale instead of forcing normal speed.")
