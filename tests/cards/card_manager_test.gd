extends "res://tests/support/test_case.gd"

const Factory = preload("res://tests/support/test_factory.gd")

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
