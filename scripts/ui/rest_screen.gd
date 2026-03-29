class_name RestScreen
extends CanvasLayer

## REST room overlay: choose to heal fully or upgrade one card.

signal rest_completed

var _content_root: VBoxContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_content_root = VBoxContainer.new()
	_content_root.set_anchors_preset(Control.PRESET_CENTER)
	_content_root.size = Vector2(600, 500)
	_content_root.position = Vector2(-300, -250)
	_content_root.alignment = BoxContainer.ALIGNMENT_CENTER
	_content_root.add_theme_constant_override("separation", 20)
	add_child(_content_root)

	_show_choice_screen()

func _show_choice_screen() -> void:
	_clear_content()

	var title := Label.new()
	title.text = "REST CHAMBER"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.5, 1.0, 0.7))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content_root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Choose your respite"
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content_root.add_child(subtitle)

	# Rest button
	var rest_btn := Button.new()
	rest_btn.text = "Rest — Heal to Full HP"
	rest_btn.custom_minimum_size = Vector2(350, 60)
	rest_btn.add_theme_font_size_override("font_size", 20)
	rest_btn.pressed.connect(_on_rest)
	_content_root.add_child(rest_btn)

	# Upgrade button
	var upgrade_btn := Button.new()
	var upgradeable_count: int = _count_upgradeable_cards()
	if upgradeable_count > 0:
		upgrade_btn.text = "Upgrade a Card (%d available)" % upgradeable_count
	else:
		upgrade_btn.text = "Upgrade a Card (none available)"
		upgrade_btn.disabled = true
	upgrade_btn.custom_minimum_size = Vector2(350, 60)
	upgrade_btn.add_theme_font_size_override("font_size", 20)
	upgrade_btn.pressed.connect(_show_upgrade_screen)
	_content_root.add_child(upgrade_btn)

	# Remove card button
	var remove_btn := Button.new()
	var can_remove: bool = GameManager.run_deck.size() > GameManager.MIN_DECK_SIZE
	if can_remove:
		remove_btn.text = "Remove a Card (%d in deck)" % GameManager.run_deck.size()
	else:
		remove_btn.text = "Remove a Card (deck at minimum)"
		remove_btn.disabled = true
	remove_btn.custom_minimum_size = Vector2(350, 60)
	remove_btn.add_theme_font_size_override("font_size", 20)
	remove_btn.pressed.connect(_show_remove_screen)
	_content_root.add_child(remove_btn)

func _show_upgrade_screen() -> void:
	_clear_content()

	var title := Label.new()
	title.text = "UPGRADE A CARD"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content_root.add_child(title)

	# Scrollable list of upgradeable cards
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(550, 350)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_root.add_child(scroll)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	for i in range(GameManager.run_deck.size()):
		var card: CardData = GameManager.run_deck[i]
		if card.upgraded_version == null or card.is_upgraded:
			continue

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		list.add_child(row)

		# Current card info
		var current_label := Label.new()
		current_label.text = "%s (Cost: %s)" % [card.card_name, card.get_cost_label()]
		current_label.add_theme_font_size_override("font_size", 16)
		current_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		current_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(current_label)

		# Arrow
		var arrow := Label.new()
		arrow.text = " >> "
		arrow.add_theme_font_size_override("font_size", 16)
		arrow.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
		row.add_child(arrow)

		# Upgraded card info
		var upgraded: CardData = card.upgraded_version
		var upgrade_label := Label.new()
		upgrade_label.text = "%s (Cost: %s)" % [upgraded.card_name, upgraded.get_cost_label()]
		upgrade_label.add_theme_font_size_override("font_size", 16)
		upgrade_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
		upgrade_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(upgrade_label)

		# Upgrade button
		var btn := Button.new()
		btn.text = "Upgrade"
		btn.custom_minimum_size = Vector2(100, 30)
		btn.add_theme_font_size_override("font_size", 14)
		var deck_index: int = i
		btn.pressed.connect(func() -> void: _on_upgrade_card(deck_index))
		row.add_child(btn)

	# Back button
	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(120, 40)
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.pressed.connect(_show_choice_screen)
	_content_root.add_child(back_btn)

func _show_remove_screen() -> void:
	_clear_content()

	var title := Label.new()
	title.text = "REMOVE A CARD"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content_root.add_child(title)

	var warning := Label.new()
	warning.text = "This is permanent! Choose carefully."
	warning.add_theme_font_size_override("font_size", 14)
	warning.add_theme_color_override("font_color", Color(0.7, 0.5, 0.5))
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content_root.add_child(warning)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(550, 350)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_root.add_child(scroll)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	for i in range(GameManager.run_deck.size()):
		var card: CardData = GameManager.run_deck[i]

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		list.add_child(row)

		var card_label := Label.new()
		card_label.text = "%s (%s)" % [card.card_name, card.get_cost_label()]
		card_label.add_theme_font_size_override("font_size", 16)
		card_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		card_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(card_label)

		var rarity_lbl := Label.new()
		rarity_lbl.add_theme_font_size_override("font_size", 14)
		match card.rarity:
			CardData.Rarity.UNCOMMON:
				rarity_lbl.text = "Uncommon"
				rarity_lbl.add_theme_color_override("font_color", Color(0.3, 0.5, 1.0))
			CardData.Rarity.RARE:
				rarity_lbl.text = "Rare"
				rarity_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
			_:
				rarity_lbl.text = "Common"
				rarity_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		row.add_child(rarity_lbl)

		var btn := Button.new()
		btn.text = "Remove"
		btn.custom_minimum_size = Vector2(100, 30)
		btn.add_theme_font_size_override("font_size", 14)
		btn.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
		var deck_index: int = i
		var row_ref: HBoxContainer = row
		btn.pressed.connect(func() -> void: _on_remove_card(deck_index, row_ref))
		row.add_child(btn)

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(120, 40)
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.pressed.connect(_show_choice_screen)
	_content_root.add_child(back_btn)

func _on_remove_card(deck_index: int, row: HBoxContainer) -> void:
	if not GameManager.remove_card_from_deck(deck_index):
		return
	row.modulate = Color(1.5, 0.3, 0.2, 1.0)
	var tween := row.create_tween().set_parallel(true)
	tween.tween_property(row, "modulate:a", 0.0, 0.4)
	tween.tween_property(row, "scale:y", 0.0, 0.3).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(_complete)

func _on_rest() -> void:
	GameManager.player_health_carry = -1.0
	_complete()

func _on_upgrade_card(deck_index: int) -> void:
	var card: CardData = GameManager.run_deck[deck_index]
	if card.upgraded_version:
		GameManager.run_deck[deck_index] = card.upgraded_version
	_complete()

func _complete() -> void:
	rest_completed.emit()
	queue_free()

func _count_upgradeable_cards() -> int:
	var count: int = 0
	for card in GameManager.run_deck:
		if card.upgraded_version != null and not card.is_upgraded:
			count += 1
	return count

func _clear_content() -> void:
	for child in _content_root.get_children():
		child.queue_free()
