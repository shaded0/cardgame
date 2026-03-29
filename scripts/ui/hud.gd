extends Control

## Player HUD container.
## Wires health/mana bars and card slots to player components and updates UI in real-time.

@onready var health_bar: ProgressBar = $HealthBar
@onready var mana_bar: ProgressBar = $ManaBar
@onready var card_hand: HBoxContainer = $CardHand
var card_slots: Array = []

func _ready() -> void:
	# HUD needs to refresh while paused so card availability still updates.
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Wait one frame so the player node has had a chance to finish _ready().
	await get_tree().process_frame
	_connect_to_player()

func _connect_to_player() -> void:
	var player: CharacterBody2D = _find_player()
	if player == null:
		push_warning("HUD: Player not found")
		return

	# Connect to player's health component signal: UI updates whenever health changes.
	var health: HealthComponent = player.get_node("HealthComponent")
	health.health_changed.connect(_on_health_changed)
	health_bar.max_value = health.max_health
	health_bar.value = health.current_health

	# Connect to player's mana component signal: UI updates on regen/spend.
	var mana: ManaComponent = player.get_node("ManaComponent")
	mana.mana_changed.connect(_on_mana_changed)
	mana_bar.max_value = mana.max_mana
	mana_bar.value = mana.current_mana

	# Connect to card manager signal: hand changes redraw slots immediately.
	var card_mgr: CardManager = player.get_node("CardManager")
	card_mgr.hand_updated.connect(_on_hand_updated)

	# Initialize references to each slot and show matching hotkey hints (1-4).
	card_slots = card_hand.get_children()
	for i in range(card_slots.size()):
		card_slots[i].slot_index = i
		var key_hint: Label = card_slots[i].get_node("VBoxContainer/KeyHint")
		key_hint.text = str(i + 1)

	# Populate hand immediately (we missed the initial hand_updated signal)
	if card_mgr.hand.size() > 0:
		_on_hand_updated(card_mgr.hand)

func _find_player() -> CharacterBody2D:
	var player: CharacterBody2D = GameManager.get_player()
	if player:
		return player
	# Fallback: find by name
	var arena: Node = get_parent().get_parent()
	return arena.find_child("Player", true, false) as CharacterBody2D

func _on_health_changed(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current

func _on_mana_changed(current: float, maximum: float) -> void:
	mana_bar.max_value = maximum
	mana_bar.value = current
	_update_card_playability()

func _on_hand_updated(hand: Array) -> void:
	# Populate or clear each slot based on current hand count.
	for i in range(card_slots.size()):
		var slot = card_slots[i]
		if i < hand.size() and hand[i] != null:
			slot.set_card_data(hand[i])
		else:
			slot.clear_card()

	# Update playability based on current mana
	_update_card_playability()

func _update_card_playability() -> void:
	# Re-query player each call so the UI reflects fresh mana and deck state.
	var player: CharacterBody2D = _find_player()
	if player == null:
		return
	var mana: ManaComponent = player.get_node("ManaComponent")
	var card_mgr: CardManager = player.get_node("CardManager")
	for i in range(card_slots.size()):
		var slot = card_slots[i]
		if slot.has_method("set_playable"):
			if i < card_mgr.hand.size() and card_mgr.hand[i] != null:
				slot.set_playable(card_mgr.can_play_card(card_mgr.hand[i], mana.current_mana))
			else:
				slot.set_playable(false)
