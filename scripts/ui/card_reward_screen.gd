class_name CardRewardScreen
extends CanvasLayer

## Post-combat card reward screen.
## Shows 3 cards to pick from (or skip). Integrates with run deck.

signal card_chosen(card: CardData)
signal rewards_skipped

var _card_options: Array[CardData] = []

func setup(class_id: StringName, is_elite: bool = false) -> void:
	var pool := CardPool.new()
	_card_options = pool.get_reward_options(class_id, 3, is_elite)
	_build_ui()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20

func _build_ui() -> void:
	# Dark overlay background
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_CENTER)
	root.size = Vector2(900, 500)
	root.position = Vector2(-450, -250)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 20)
	add_child(root)

	# Title
	var title := Label.new()
	title.text = "CHOOSE A CARD"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	# Card row
	var card_row := HBoxContainer.new()
	card_row.alignment = BoxContainer.ALIGNMENT_CENTER
	card_row.add_theme_constant_override("separation", 30)
	card_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(card_row)

	for i in range(_card_options.size()):
		var card: CardData = _card_options[i]
		var panel: PanelContainer = _create_card_panel(card, i)
		card_row.add_child(panel)

	if _card_options.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No new cards available"
		empty_label.add_theme_font_size_override("font_size", 20)
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card_row.add_child(empty_label)

	# Skip button
	var skip_btn := Button.new()
	skip_btn.text = "Skip"
	skip_btn.custom_minimum_size = Vector2(150, 40)
	skip_btn.add_theme_font_size_override("font_size", 18)
	skip_btn.pressed.connect(_on_skip)
	root.add_child(skip_btn)
	root.move_child(skip_btn, -1)

func _create_card_panel(card: CardData, index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(240, 320)

	# Rarity-colored border
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12, 0.95)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 16
	style.content_margin_bottom = 16

	match card.rarity:
		CardData.Rarity.COMMON:
			style.border_color = Color(0.6, 0.6, 0.6)
		CardData.Rarity.UNCOMMON:
			style.border_color = Color(0.3, 0.5, 1.0)
		CardData.Rarity.RARE:
			style.border_color = Color(1.0, 0.8, 0.2)

	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# Rarity label
	var rarity_label := Label.new()
	match card.rarity:
		CardData.Rarity.COMMON:
			rarity_label.text = "Common"
			rarity_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		CardData.Rarity.UNCOMMON:
			rarity_label.text = "Uncommon"
			rarity_label.add_theme_color_override("font_color", Color(0.3, 0.5, 1.0))
		CardData.Rarity.RARE:
			rarity_label.text = "Rare"
			rarity_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	rarity_label.add_theme_font_size_override("font_size", 12)
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(rarity_label)

	# Card name
	var name_label := Label.new()
	name_label.text = card.card_name
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# Mana cost
	var cost_label := Label.new()
	cost_label.text = "Cost: %s" % card.get_cost_label()
	cost_label.add_theme_font_size_override("font_size", 16)
	cost_label.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(cost_label)

	# Separator
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Description
	var desc_label := Label.new()
	desc_label.text = card.description
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc_label)

	# Exhaust badge
	if card.exhaust:
		var exhaust_label := Label.new()
		exhaust_label.text = "Exhaust"
		exhaust_label.add_theme_font_size_override("font_size", 12)
		exhaust_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		exhaust_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(exhaust_label)

	# Make clickable
	var btn := Button.new()
	btn.text = "Take"
	btn.custom_minimum_size = Vector2(100, 30)
	btn.add_theme_font_size_override("font_size", 16)
	btn.pressed.connect(func() -> void: _on_card_picked(index))
	vbox.add_child(btn)

	# Entrance animation
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.8, 0.8)
	var tween := panel.create_tween().set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.3).set_delay(float(index) * 0.15)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.3).set_delay(float(index) * 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	return panel

func _on_card_picked(index: int) -> void:
	if index >= 0 and index < _card_options.size():
		card_chosen.emit(_card_options[index])
	queue_free()

func _on_skip() -> void:
	rewards_skipped.emit()
	queue_free()
