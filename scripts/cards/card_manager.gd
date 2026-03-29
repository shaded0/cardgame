class_name CardManager
extends Node

signal card_played(card: Resource, slot_index: int)
signal hand_updated(hand: Array)

const HAND_SIZE: int = 4

var deck: Array[Resource] = []  # Full card pool
var draw_pile: Array[Resource] = []
var hand: Array[Resource] = []

func _ready() -> void:
	# Will be initialized when class is selected
	pass

func initialize_deck(card_pool: Array) -> void:
	deck = card_pool.duplicate()
	draw_pile = deck.duplicate()
	draw_pile.shuffle()
	hand.clear()

	# Draw initial hand
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

	# Check mana cost
	var player: CharacterBody2D = get_parent() as CharacterBody2D
	var mana_comp: ManaComponent = player.get_node("ManaComponent")
	if not mana_comp.spend_mana(card.mana_cost):
		return  # Not enough mana

	# Generate mana if card produces it
	if card.generates_mana > 0:
		mana_comp.add_mana(card.generates_mana)

	# Emit the card played signal
	card_played.emit(card, slot_index)

	# Replace the card in hand
	_replace_card(slot_index, card)
	hand_updated.emit(hand)

func _replace_card(slot_index: int, played_card: Resource) -> void:
	# Mage chain mechanic: if card has a chain_card, use that instead
	if played_card.chain_card != null:
		hand[slot_index] = played_card.chain_card
		return

	# Normal draw from pile
	if draw_pile.size() == 0:
		draw_pile = deck.duplicate()
		draw_pile.shuffle()

	hand[slot_index] = draw_pile.pop_back()
