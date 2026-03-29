extends Control

## Player HUD container.
## Wires health/mana bars and card slots to player components and updates UI in real-time.

@onready var health_bar: ProgressBar = $HealthBar
@onready var mana_bar: ProgressBar = $ManaBar
@onready var card_hand: HBoxContainer = $CardHand
var card_slots: Array = []
var draw_counter_label: Label = null
var _deck_viewer: CanvasLayer = null

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
	var health_changed_cb := Callable(self, "_on_health_changed")
	if not health.health_changed.is_connected(health_changed_cb):
		health.health_changed.connect(health_changed_cb)
	health_bar.max_value = health.max_health
	health_bar.value = health.current_health

	# Connect to player's mana component signal: UI updates on regen/spend.
	var mana: ManaComponent = player.get_node("ManaComponent")
	var mana_changed_cb := Callable(self, "_on_mana_changed")
	if not mana.mana_changed.is_connected(mana_changed_cb):
		mana.mana_changed.connect(mana_changed_cb)
	mana_bar.max_value = mana.max_mana
	mana_bar.value = mana.current_mana

	# Connect to card manager signal: hand changes redraw slots immediately.
	var card_mgr: CardManager = player.get_node("CardManager")
	card_mgr.hand_updated.connect(Callable(self, "_on_hand_updated"))
	card_mgr.draw_pile_changed.connect(Callable(self, "_on_draw_pile_changed"))
	card_mgr.deck_reshuffled.connect(Callable(self, "_on_deck_reshuffled"))
	card_mgr.card_cycled.connect(Callable(self, "_on_card_cycled"))
	card_mgr.card_played.connect(Callable(self, "_on_card_played_synergy"))

	# Initialize references to each slot and show matching hotkey hints (1-4).
	card_slots = card_hand.get_children()
	for i in range(card_slots.size()):
		card_slots[i].slot_index = i
		var key_hint: Label = card_slots[i].get_node("VBoxContainer/KeyHint")
		key_hint.text = str(i + 1)

	# Draw pile counter above the card hand
	draw_counter_label = Label.new()
	draw_counter_label.text = "Draw: %d" % card_mgr.draw_pile.size()
	draw_counter_label.add_theme_font_size_override("font_size", 16)
	draw_counter_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	draw_counter_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	draw_counter_label.position = Vector2(card_hand.position.x, card_hand.position.y - 24)
	add_child(draw_counter_label)

	# Populate hand immediately (we missed the initial hand_updated signal)
	if card_mgr.hand.size() > 0:
		_on_hand_updated(card_mgr.hand)

	_animate_entrance()

func _find_player() -> PlayerController:
	var player: PlayerController = GameManager.get_player()
	if player:
		return player
	# Fallback: find by name
	var arena: Node = get_parent().get_parent()
	return arena.find_child("Player", true, false) as PlayerController

func _animate_entrance() -> void:
	# Health bar slides in from left
	var hb_target_x := health_bar.position.x
	health_bar.position.x = -health_bar.size.x
	health_bar.modulate.a = 0.0
	var hb_tween := health_bar.create_tween().set_parallel(true)
	hb_tween.tween_property(health_bar, "position:x", hb_target_x, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	hb_tween.tween_property(health_bar, "modulate:a", 1.0, 0.3)

	# Mana bar slides in from left with slight delay
	var mb_target_x := mana_bar.position.x
	mana_bar.position.x = -mana_bar.size.x
	mana_bar.modulate.a = 0.0
	var mb_tween := mana_bar.create_tween().set_parallel(true)
	mb_tween.tween_property(mana_bar, "position:x", mb_target_x, 0.4).set_delay(0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	mb_tween.tween_property(mana_bar, "modulate:a", 1.0, 0.3).set_delay(0.1)

	# Draw counter fades in with mana bar
	if draw_counter_label:
		draw_counter_label.modulate.a = 0.0
		var dc_tween := draw_counter_label.create_tween()
		dc_tween.tween_property(draw_counter_label, "modulate:a", 1.0, 0.3).set_delay(0.15)

	# Card hand rises from bottom
	var ch_target_y := card_hand.position.y
	card_hand.position.y += 80.0
	card_hand.modulate.a = 0.0
	var ch_tween := card_hand.create_tween().set_parallel(true)
	ch_tween.tween_property(card_hand, "position:y", ch_target_y, 0.5).set_delay(0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	ch_tween.tween_property(card_hand, "modulate:a", 1.0, 0.35).set_delay(0.2)

func _on_health_changed(current: float, maximum: float) -> void:
	health_bar.set_health(current, maximum)

func _on_mana_changed(current: float, maximum: float) -> void:
	mana_bar.set_mana(current, maximum)
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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("view_deck"):
		if _deck_viewer:
			_hide_deck_viewer()
		else:
			_show_deck_viewer()

func _on_draw_pile_changed(count: int) -> void:
	if draw_counter_label:
		draw_counter_label.text = "Draw: %d" % count

func _on_deck_reshuffled() -> void:
	if draw_counter_label == null:
		return
	draw_counter_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	var tween := create_tween()
	tween.tween_property(draw_counter_label, "scale", Vector2(1.3, 1.3), 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(draw_counter_label, "scale", Vector2(1.0, 1.0), 0.2)
	tween.tween_callback(func():
		draw_counter_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	)

func _on_card_cycled(_old_card: CardData, _new_card: CardData, slot_index: int) -> void:
	if slot_index >= 0 and slot_index < card_slots.size():
		card_slots[slot_index].play_cycle_animation()

func _on_card_played_synergy(_card: CardData, played_slot: int, _mana_spent: float) -> void:
	# Immediate visual feedback on the played slot
	if played_slot >= 0 and played_slot < card_slots.size():
		if card_slots[played_slot].has_method("play_used_feedback"):
			card_slots[played_slot].play_used_feedback()

	var player := _find_player()
	if player == null:
		return
	var card_mgr: CardManager = player.get_node("CardManager")

	# Wait one frame so CardEffectResolver has applied buffs/debuffs
	await get_tree().process_frame

	for i in range(card_slots.size()):
		if i == played_slot:
			continue
		if i >= card_mgr.hand.size() or card_mgr.hand[i] == null:
			continue
		if SynergyChecker.check_synergy(card_mgr.hand[i], player):
			card_slots[i].play_synergy_glow()

func _show_deck_viewer() -> void:
	var player := _find_player()
	if player == null:
		return
	var card_mgr: CardManager = player.get_node("CardManager")
	var status: Dictionary = card_mgr.get_deck_status()

	_deck_viewer = CanvasLayer.new()
	_deck_viewer.layer = 15
	add_child(_deck_viewer)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_deck_viewer.add_child(bg)

	var center := Control.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.size = Vector2(900, 500)
	center.position = Vector2(-450, -250)
	_deck_viewer.add_child(center)

	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 40)
	center.add_child(root)

	var groups: Array[Dictionary] = [
		{"title": "In Hand", "cards": status.hand, "color": Color(0.4, 1.0, 0.5)},
		{"title": "Draw Pile (%d)" % status.draw_pile.size(), "cards": status.draw_pile, "color": Color(0.6, 0.7, 0.8)},
		{"title": "Exhausted", "cards": status.exhaust_pile, "color": Color(1.0, 0.4, 0.4)},
	]
	for group_data in groups:
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		root.add_child(col)
		var title := Label.new()
		title.text = group_data.title
		title.add_theme_font_size_override("font_size", 20)
		title.add_theme_color_override("font_color", group_data.color)
		col.add_child(title)
		for card: CardData in group_data.cards:
			if card == null:
				continue
			var lbl := Label.new()
			lbl.text = "%s (%s)" % [card.card_name, card.get_cost_label()]
			lbl.add_theme_font_size_override("font_size", 14)
			col.add_child(lbl)

func _hide_deck_viewer() -> void:
	if _deck_viewer:
		_deck_viewer.queue_free()
		_deck_viewer = null

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
