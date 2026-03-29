class_name CardManager
extends Node

signal card_played(card: Resource, slot_index: int)
signal hand_updated(hand: Array)

const HAND_SIZE: int = 4

var deck: Array[Resource] = []
var draw_pile: Array[Resource] = []
var hand: Array[Resource] = []

func _ready() -> void:
	# CardManager must process input even while paused so players can play cards
	process_mode = Node.PROCESS_MODE_ALWAYS

func initialize_deck(card_pool: Array) -> void:
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

	hand_updated.emit(hand)

func _unhandled_input(event: InputEvent) -> void:
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
	if not mana_comp.spend_mana(card.mana_cost):
		return

	if card.generates_mana > 0:
		mana_comp.add_mana(card.generates_mana)

	# If game is paused (player is reading cards), unpause before resolving
	var was_paused: bool = get_tree().paused
	if was_paused:
		GameManager.toggle_pause()

	# Emit card played — resolver handles effects and visuals
	card_played.emit(card, slot_index)

	# Replace the card in hand
	_replace_card(slot_index, card)
	hand_updated.emit(hand)

	# If the card has pauses_game, pause after a brief delay so the effect is visible
	if card.pauses_game and not was_paused:
		_pause_after_delay(0.4)

func _replace_card(slot_index: int, played_card: Resource) -> void:
	if played_card.chain_card != null:
		hand[slot_index] = played_card.chain_card
		return

	if draw_pile.size() == 0:
		draw_pile = deck.duplicate()
		draw_pile.shuffle()

	hand[slot_index] = draw_pile.pop_back()

func _pause_after_delay(delay: float) -> void:
	var timer: SceneTreeTimer = get_tree().create_timer(delay, true, false, true)
	timer.timeout.connect(func() -> void:
		if not get_tree().paused:
			GameManager.toggle_pause()
	)
