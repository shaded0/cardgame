class_name CardManager
extends Node

## Owns deck/draw hand lifecycle and handles input for numbered card slots.
## Emits signals so UI and gameplay systems stay decoupled.

signal card_played(card: Resource, slot_index: int)
signal hand_updated(hand: Array)

const HAND_SIZE: int = 4

var deck: Array[Resource] = []
var draw_pile: Array[Resource] = []
var hand: Array[Resource] = []

func _ready() -> void:
	# Input must still work in pause overlay, so use PROCESS_MODE_ALWAYS.
	process_mode = Node.PROCESS_MODE_ALWAYS

func initialize_deck(card_pool: Array) -> void:
	# Duplicate resources so we can mutate draw/hand without touching class config assets.
	deck = card_pool.duplicate()
	draw_pile = deck.duplicate()
	draw_pile.shuffle()
	hand.clear()

	for i in range(HAND_SIZE):
		if draw_pile.size() > 0:
			hand.append(draw_pile.pop_back())
		else:
			draw_pile = deck.duplicate()
			draw_pile.shuffle()
			hand.append(draw_pile.pop_back())

	# Inform UI immediately with first draw.
	hand_updated.emit(hand)

func _unhandled_input(event: InputEvent) -> void:
	# Number keys are mapped to play_card_1...4 in InputMap.
	for i in range(HAND_SIZE):
		if event.is_action_pressed("play_card_%d" % (i + 1)):
			try_play_card(i)
			return

func try_play_card(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= hand.size():
		return

	var card: Resource = hand[slot_index]
	if card == null:
		return

	var player: CharacterBody2D = get_parent() as CharacterBody2D
	var mana_comp: ManaComponent = player.get_node("ManaComponent")
	# Early out if card is too expensive.
	if not mana_comp.spend_mana(card.mana_cost):
		return

	if card.generates_mana > 0:
		mana_comp.add_mana(card.generates_mana)

	# If game is paused, unpause before resolving so effects and spawned nodes are visible.
	var was_paused: bool = get_tree().paused
	if was_paused:
		GameManager.toggle_pause()

	# Emit card played — resolver node handles actual effect resolution.
	card_played.emit(card, slot_index)

	# Replace the card in hand according to chain-card or draw-pile logic.
	_replace_card(slot_index, card)
	hand_updated.emit(hand)

	# If the card has pauses_game, re-pause after a short delay so effect timing is visible.
	if card.pauses_game and not was_paused:
		_pause_after_delay(0.4)

func _replace_card(slot_index: int, played_card: Resource) -> void:
	# Chain cards allow a card to become another card when played (e.g., combos).
	if played_card.chain_card != null:
		hand[slot_index] = played_card.chain_card
		return

	if draw_pile.size() == 0:
		draw_pile = deck.duplicate()
		draw_pile.shuffle()

	hand[slot_index] = draw_pile.pop_back()

func _pause_after_delay(delay: float) -> void:
	# Use a one-shot timer, with "process in pause" so it still runs after pausing.
	var timer: SceneTreeTimer = get_tree().create_timer(delay, true, false, true)
	timer.timeout.connect(func() -> void:
		if not get_tree().paused:
			GameManager.toggle_pause()
	)
