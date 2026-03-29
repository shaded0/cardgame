class_name CardManager
extends Node

## Owns deck/draw/hand lifecycle and handles input for numbered card slots.
## Supports exhaust (one-time cards) and X-cost (spend-all-mana) mechanics.

signal card_played(card: CardData, slot_index: int, mana_spent: float)
signal hand_updated(hand: Array[CardData])
signal card_exhausted(card: CardData)

const HAND_SIZE: int = 4

var deck: Array[CardData] = []
var draw_pile: Array[CardData] = []
var hand: Array[CardData] = []
var exhaust_pile: Array[CardData] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func initialize_deck(card_pool: Array[CardData]) -> void:
	deck = card_pool.duplicate()
	draw_pile = deck.duplicate()
	draw_pile.shuffle()
	hand.clear()
	exhaust_pile.clear()

	if deck.is_empty():
		hand_updated.emit(hand.duplicate())
		return

	for i in range(HAND_SIZE):
		hand.append(_draw_next_card())

	hand_updated.emit(hand.duplicate())

func _unhandled_input(event: InputEvent) -> void:
	for i in range(HAND_SIZE):
		if event.is_action_pressed("play_card_%d" % (i + 1)):
			try_play_card(i)
			return

func try_play_card(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= hand.size():
		return

	var card: CardData = hand[slot_index]
	if card == null:
		return

	var player: CharacterBody2D = get_parent() as CharacterBody2D
	if player == null:
		return

	var mana_comp: ManaComponent = player.get_node_or_null("ManaComponent")
	if mana_comp == null:
		return

	if not can_play_card(card, mana_comp.current_mana):
		return

	var mana_to_spend: float = _get_mana_to_spend(card, mana_comp.current_mana)

	if not mana_comp.spend_mana(mana_to_spend):
		return

	if card.generates_mana > 0:
		mana_comp.add_mana(card.generates_mana)

	var was_paused: bool = get_tree().paused
	if was_paused:
		GameManager.toggle_pause()

	card_played.emit(card, slot_index, mana_to_spend)

	_replace_card(slot_index, card)
	hand_updated.emit(hand.duplicate())

	if card.pauses_game and not was_paused:
		_pause_after_delay(0.4)

func _replace_card(slot_index: int, played_card: CardData) -> void:
	# Chain cards transform into a follow-up card.
	if played_card.chain_card != null:
		hand[slot_index] = played_card.chain_card
		return

	# Exhaust: remove from deck permanently (for this combat).
	if played_card.exhaust:
		exhaust_pile.append(played_card)
		deck.erase(played_card)
		card_exhausted.emit(played_card)

	hand[slot_index] = _draw_next_card()

func _pause_after_delay(delay: float) -> void:
	var timer: SceneTreeTimer = get_tree().create_timer(delay, true, false, true)
	timer.timeout.connect(func() -> void:
		if not is_instance_valid(self) or not is_inside_tree():
			return
		if not get_tree().paused:
			GameManager.toggle_pause()
	)

func can_play_card(card: CardData, available_mana: float) -> bool:
	if card == null:
		return false
	return _get_mana_to_spend(card, available_mana) > 0.0

func _get_mana_to_spend(card: CardData, available_mana: float) -> float:
	if card.is_x_cost:
		return maxf(available_mana, 0.0)
	return float(card.mana_cost) if available_mana >= card.mana_cost else 0.0

func _draw_next_card() -> CardData:
	if draw_pile.is_empty():
		draw_pile = deck.duplicate()
		draw_pile.shuffle()

	if draw_pile.is_empty():
		return null

	return draw_pile.pop_back()
