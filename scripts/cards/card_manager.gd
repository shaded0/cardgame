class_name CardManager
extends Node

## Owns deck/draw/hand lifecycle and handles input for numbered card slots.
## Supports exhaust (one-time cards) and X-cost (spend-all-mana) mechanics.

signal card_played(card: CardData, slot_index: int, mana_spent: float)
signal hand_updated(hand: Array[CardData])
signal card_exhausted(card: CardData)
signal tactical_focus_changed(active: bool)
signal card_cycled(old_card: CardData, new_card: CardData, slot_index: int)
signal draw_pile_changed(count: int)
signal deck_reshuffled

const HAND_SIZE: int = 4
const TACTICAL_TIME_SCALE: float = 0.15  ## 15% speed — slow enough to read cards, fast enough to feel alive
const CYCLE_MANA_COST: int = 5
const CYCLE_COOLDOWN: float = 1.5

var deck: Array[CardData] = []
var draw_pile: Array[CardData] = []
var hand: Array[CardData] = []
var exhaust_pile: Array[CardData] = []
var _tactical_focus_active: bool = false
var _base_time_scale: float = 1.0  ## Track non-tactical time scale so hitstop/etc. can coexist
var _cycle_cooldown_timer: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _notification(what: int) -> void:
	# Restore time scale if we're removed mid-tactical-focus (scene change, death, etc.)
	if what == NOTIFICATION_PREDELETE or what == NOTIFICATION_EXIT_TREE:
		if _tactical_focus_active:
			_tactical_focus_active = false
			Engine.time_scale = 1.0

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
	draw_pile_changed.emit(draw_pile.size())

func _process(_delta: float) -> void:
	if _cycle_cooldown_timer > 0.0:
		_cycle_cooldown_timer -= _delta

	# Tactical focus: hold RMB or Shift to slow time while choosing cards.
	# Using _process instead of _input because we need to detect held state, not just press/release.
	if get_tree().paused:
		# Don't fight with the pause system
		if _tactical_focus_active:
			_end_tactical_focus()
		return

	if Input.is_action_pressed("tactical_focus"):
		if not _tactical_focus_active:
			_begin_tactical_focus()
	else:
		if _tactical_focus_active:
			_end_tactical_focus()

func _unhandled_input(event: InputEvent) -> void:
	for i in range(HAND_SIZE):
		if event.is_action_pressed("cycle_card_%d" % (i + 1)):
			try_cycle_card(i)
			return
	for i in range(HAND_SIZE):
		if event.is_action_pressed("play_card_%d" % (i + 1)):
			try_play_card(i)
			return

func _begin_tactical_focus() -> void:
	_tactical_focus_active = true
	_base_time_scale = Engine.time_scale
	Engine.time_scale = TACTICAL_TIME_SCALE
	tactical_focus_changed.emit(true)

func _end_tactical_focus() -> void:
	_tactical_focus_active = false
	Engine.time_scale = _base_time_scale
	tactical_focus_changed.emit(false)

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

	# If paused (legacy path), unpause on card play.
	if get_tree().paused:
		GameManager.toggle_pause()

	card_played.emit(card, slot_index, mana_to_spend)

	_replace_card(slot_index, card)
	hand_updated.emit(hand.duplicate())

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

func can_play_card(card: CardData, available_mana: float) -> bool:
	if card == null:
		return false
	return _get_mana_to_spend(card, available_mana) > 0.0

func _get_mana_to_spend(card: CardData, available_mana: float) -> float:
	if card.is_x_cost:
		return maxf(available_mana, 0.0)
	return float(card.mana_cost) if available_mana >= card.mana_cost else 0.0

func try_cycle_card(slot_index: int) -> void:
	if _cycle_cooldown_timer > 0.0:
		return
	if slot_index < 0 or slot_index >= hand.size():
		return
	var old_card: CardData = hand[slot_index]
	if old_card == null:
		return

	var player: CharacterBody2D = get_parent() as CharacterBody2D
	if player == null:
		return
	var mana_comp: ManaComponent = player.get_node_or_null("ManaComponent")
	if mana_comp == null:
		return
	if not mana_comp.spend_mana(CYCLE_MANA_COST):
		return

	# Shuffle old card back into draw pile at a random position
	if draw_pile.is_empty():
		draw_pile.append(old_card)
	else:
		draw_pile.insert(randi() % draw_pile.size(), old_card)

	var new_card: CardData = _draw_next_card()
	hand[slot_index] = new_card

	_cycle_cooldown_timer = CYCLE_COOLDOWN
	card_cycled.emit(old_card, new_card, slot_index)
	hand_updated.emit(hand.duplicate())

func get_deck_status() -> Dictionary:
	return {
		"hand": hand.duplicate(),
		"draw_pile": draw_pile.duplicate(),
		"exhaust_pile": exhaust_pile.duplicate(),
	}

func _draw_next_card() -> CardData:
	if draw_pile.is_empty():
		draw_pile = deck.duplicate()
		draw_pile.shuffle()
		deck_reshuffled.emit()

	if draw_pile.is_empty():
		draw_pile_changed.emit(0)
		return null

	var card: CardData = draw_pile.pop_back()
	draw_pile_changed.emit(draw_pile.size())
	return card
