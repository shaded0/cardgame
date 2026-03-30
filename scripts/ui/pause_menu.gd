extends Control

## PauseMenu is always loaded from the HUD as an overlay.
## It listens to GameManager pause state signals and lets players queue/inspect cards while paused.

## UI nodes referenced from the scene tree.
## `@onready` guarantees these paths are resolved after the node enters the scene.
@onready var card_details: VBoxContainer = $Panel/VBoxContainer/CardDetails
@onready var resume_btn: Button = $Panel/VBoxContainer/ResumeButton
@onready var quit_btn: Button = $Panel/VBoxContainer/QuitButton
@onready var overlay: ColorRect = $Overlay
@onready var panel: PanelContainer = $Panel

var _close_tween: Tween = null

func _ready() -> void:
	# While paused, regular physics still stops but this UI remains active.
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false

	# Wire button clicks to handlers.
	resume_btn.pressed.connect(_on_resume)
	quit_btn.pressed.connect(_on_quit)

	# Style the panel and buttons
	_style_panel()
	_style_buttons()

	# React to global pause events emitted by GameManager.
	var paused_cb := Callable(self, "_on_game_paused")
	if not GameManager.game_paused.is_connected(paused_cb):
		GameManager.game_paused.connect(paused_cb)
	var resumed_cb := Callable(self, "_on_game_resumed")
	if not GameManager.game_resumed.is_connected(resumed_cb):
		GameManager.game_resumed.connect(resumed_cb)

func _exit_tree() -> void:
	var paused_cb := Callable(self, "_on_game_paused")
	if GameManager.game_paused.is_connected(paused_cb):
		GameManager.game_paused.disconnect(paused_cb)
	var resumed_cb := Callable(self, "_on_game_resumed")
	if GameManager.game_resumed.is_connected(resumed_cb):
		GameManager.game_resumed.disconnect(resumed_cb)

func _on_game_paused() -> void:
	if _close_tween and _close_tween.is_valid():
		_close_tween.kill()

	visible = true
	_populate_card_details()

	# Animate open: overlay fades, panel scales in
	overlay.modulate.a = 0.0
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.85, 0.85)
	panel.pivot_offset = panel.size / 2.0

	var tween := create_tween().set_parallel(true)
	tween.tween_property(overlay, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(panel, "modulate:a", 1.0, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.chain().tween_callback(func(): resume_btn.grab_focus())

func _on_game_resumed() -> void:
	# Animate close: shrink and fade out
	if _close_tween and _close_tween.is_valid():
		_close_tween.kill()
	_close_tween = create_tween().set_parallel(true)
	_close_tween.tween_property(overlay, "modulate:a", 0.0, 0.15)
	_close_tween.tween_property(panel, "scale", Vector2(0.9, 0.9), 0.15).set_ease(Tween.EASE_IN)
	_close_tween.tween_property(panel, "modulate:a", 0.0, 0.15)
	_close_tween.chain().tween_callback(func(): visible = false)

func _style_panel() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.1, 0.95)
	style.border_color = Color(0.4, 0.3, 0.2, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)

func _style_buttons() -> void:
	for btn in [resume_btn, quit_btn]:
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color(0.08, 0.08, 0.14, 0.9)
		normal.border_color = Color(0.4, 0.3, 0.2, 0.6)
		normal.set_border_width_all(2)
		normal.set_corner_radius_all(8)
		normal.set_content_margin_all(12)
		btn.add_theme_stylebox_override("normal", normal)

		var hover := StyleBoxFlat.new()
		hover.bg_color = Color(0.12, 0.1, 0.16, 0.95)
		hover.border_color = Color(1.0, 0.5, 0.2, 0.8)
		hover.set_border_width_all(3)
		hover.set_corner_radius_all(8)
		hover.set_content_margin_all(12)
		btn.add_theme_stylebox_override("hover", hover)

		var pressed := StyleBoxFlat.new()
		pressed.bg_color = Color(0.2, 0.12, 0.08, 0.95)
		pressed.border_color = Color(1.0, 0.7, 0.3, 1.0)
		pressed.set_border_width_all(3)
		pressed.set_corner_radius_all(8)
		pressed.set_content_margin_all(12)
		btn.add_theme_stylebox_override("pressed", pressed)

		var focus := StyleBoxFlat.new()
		focus.bg_color = Color(0.12, 0.1, 0.16, 0.95)
		focus.border_color = Color(1.0, 0.5, 0.2, 0.8)
		focus.set_border_width_all(3)
		focus.set_corner_radius_all(8)
		focus.set_content_margin_all(12)
		btn.add_theme_stylebox_override("focus", focus)

		btn.add_theme_color_override("font_color", Color(0.9, 0.85, 0.8, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.8, 0.5, 1.0))
		btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.9, 0.6, 1.0))
		btn.add_theme_color_override("font_focus_color", Color(1.0, 0.8, 0.5, 1.0))

		btn.mouse_entered.connect(func(): _pulse_button(btn))
		btn.focus_entered.connect(func(): _pulse_button(btn))

func _pulse_button(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0
	var tween := create_tween()
	tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_IN)

func _populate_card_details() -> void:
	# Clear old rows so each pause state is freshly rendered.
	for child in card_details.get_children():
		child.queue_free()

	# Look up the player by group (faster than hardcoding scene paths).
	var player: PlayerController = GameManager.get_player()
	if player == null:
		return
	var card_mgr: CardManager = player.get_node("CardManager")
	var mana_comp: ManaComponent = player.get_node("ManaComponent")

	var hint := Label.new()
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0, 0.8))
	hint.text = "Press 1-4 to play cards while paused"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_details.add_child(hint)

	# Create one label per card slot and color it based on affordability.
	for i in range(card_mgr.hand.size()):
		var card: CardData = card_mgr.hand[i]
		if card == null:
			continue

		var label := Label.new()
		label.add_theme_font_size_override("font_size", 16)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD

		var can_afford: bool = card_mgr.can_play_card(card, mana_comp.current_mana)
		var cost_str: String = card.get_cost_label()

		# Build detail line with rarity and exhaust info.
		var tags: String = ""
		match card.rarity:
			CardData.Rarity.UNCOMMON:
				tags += "[Uncommon] "
			CardData.Rarity.RARE:
				tags += "[Rare] "
		if card.exhaust:
			tags += "[Exhaust] "

		label.text = "[%d] %s%s (%s mana)\n    %s" % [i + 1, tags, card.card_name, cost_str, card.description]

		if can_afford:
			# Color by rarity
			match card.rarity:
				CardData.Rarity.RARE:
					label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5, 1.0))
				CardData.Rarity.UNCOMMON:
					label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0, 1.0))
				_:
					label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		else:
			label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.6))

		card_details.add_child(label)

func _on_resume() -> void:
	# Delegate actual pause state changes to centralized game manager.
	GameManager.toggle_pause()

func _on_quit() -> void:
	# Let GameManager own the unpause + transition flow so quit uses one path.
	GameManager.go_to_class_select()
