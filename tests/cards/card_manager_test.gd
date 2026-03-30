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

func test_reshuffle_does_not_duplicate_other_cards_still_in_hand() -> void:
	var player := Factory.make_player(root)
	var mana = Factory.add_mana(player, 100.0, 10.0)
	var card_manager: CardManager = Factory.add_card_manager(player)
	var a = Factory.make_card("A", 0)
	var b = Factory.make_card("B", 0)
	var c = Factory.make_card("C", 0)
	var d = Factory.make_card("D", 0)
	card_manager.deck = [a, b, c, d]
	card_manager.draw_pile = []
	card_manager.hand = [a, b, c, d]

	card_manager.try_play_card(0)

	assert_eq(mana.current_mana, 10.0, "Playing a zero-cost card through the reshuffle path should not spend mana.")
	assert_eq(card_manager.hand[1], b, "Reshuffling should not replace or duplicate cards that are still in hand.")
	assert_eq(card_manager.hand[2], c, "Reshuffling should preserve the other live hand slots.")
	assert_eq(card_manager.hand[3], d, "Reshuffling should not draw cards that are already visible in hand.")
	assert_eq(card_manager.hand[0], a, "With only the played card eligible for reshuffle, the replacement draw should come from that spent card.")

func test_reshuffle_preserves_duplicate_copies_not_currently_in_hand() -> void:
	var player := Factory.make_player(root)
	Factory.add_mana(player, 100.0, 10.0)
	var card_manager: CardManager = Factory.add_card_manager(player)
	var strike = Factory.make_card("Strike", 0)
	var defend = Factory.make_card("Defend", 0)
	var charge = Factory.make_card("Charge", 0)
	card_manager.deck = [strike, strike, defend, charge]
	card_manager.draw_pile = []
	card_manager.hand = [strike, defend, charge, null]

	var reshuffle := card_manager._build_reshuffle_pile(true)

	assert_eq(reshuffle.size(), 1, "Reshuffle should exclude only the exact number of cards currently held, not every duplicate copy of the same card resource.")
	assert_eq(reshuffle[0], strike, "Duplicate copies that are not in hand should remain eligible for reshuffle draws.")

func test_empty_reshuffle_does_not_emit_deck_reshuffled() -> void:
	var player := Factory.make_player(root)
	Factory.add_mana(player, 100.0, 10.0)
	var card_manager: CardManager = Factory.add_card_manager(player)
	var strike = Factory.make_card("Strike", 0)
	var defend = Factory.make_card("Defend", 0)
	card_manager.deck = [strike, defend]
	card_manager.draw_pile = []
	card_manager.hand = [strike, defend]

	var reshuffle_count := 0
	card_manager.deck_reshuffled.connect(func() -> void:
		reshuffle_count += 1
	)

	var drawn := card_manager._draw_next_card()

	assert_eq(drawn, null, "Drawing from an empty deck with no eligible reshuffle cards should safely return null.")
	assert_eq(reshuffle_count, 0, "CardManager should not emit deck_reshuffled when no actual reshuffle occurred.")

func test_initialize_deck_resets_transient_card_combat_state() -> void:
	Engine.time_scale = 0.65
	var player := Factory.make_player(root)
	Factory.add_mana(player, 100.0, 20.0)
	var card_manager: CardManager = Factory.add_card_manager(player)
	var free_card = Factory.make_card("Free", 0)
	var costed_card = Factory.make_card("Costed", 5)

	card_manager._cycle_cooldown_timer = 0.9
	card_manager._mana_cost_modifier = 3.0
	card_manager._begin_tactical_focus()

	card_manager.initialize_deck([free_card, costed_card])

	assert_eq(card_manager._cycle_cooldown_timer, 0.0, "Initializing a new deck should clear card-cycle cooldown so a fresh combat does not inherit stale input lockouts.")
	assert_eq(card_manager._mana_cost_modifier, 0.0, "Initializing a new deck should clear temporary mana cost debuffs from the previous combat.")
	assert_false(card_manager._tactical_focus_active, "Initializing a new deck should exit tactical focus instead of leaving the card system in a slowed selection state.")
	assert_near(Engine.time_scale, 0.65, 0.001, "Resetting the deck should restore the pre-focus time scale instead of leaking tactical slowdown into the new deck state.")
	assert_true(card_manager.can_play_card(costed_card, 5.0), "Freshly initialized decks should use the card's real cost after temporary modifiers are cleared.")
