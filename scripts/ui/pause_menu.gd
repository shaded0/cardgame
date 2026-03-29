extends Control

## PauseMenu is always loaded from the HUD as an overlay.
## It listens to GameManager pause state signals and lets players queue/inspect cards while paused.

## UI nodes referenced from the scene tree.
## `@onready` guarantees these paths are resolved after the node enters the scene.
@onready var card_details: VBoxContainer = $Panel/VBoxContainer/CardDetails
@onready var resume_btn: Button = $Panel/VBoxContainer/ResumeButton
@onready var quit_btn: Button = $Panel/VBoxContainer/QuitButton

func _ready() -> void:
	# While paused, regular physics still stops but this UI remains active.
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false

	# Wire button clicks to handlers.
	resume_btn.pressed.connect(_on_resume)
	quit_btn.pressed.connect(_on_quit)

	# React to global pause events emitted by GameManager.
	GameManager.game_paused.connect(_on_game_paused)
	GameManager.game_resumed.connect(_on_game_resumed)

func _on_game_paused() -> void:
	# Build the card list each time pause opens because hand can change.
	visible = true
	_populate_card_details()
	resume_btn.grab_focus()

func _on_game_resumed() -> void:
	# Hide only; HUD will stay updated by its own manager signals.
	visible = false

func _populate_card_details() -> void:
	# Clear old rows so each pause state is freshly rendered.
	for child in card_details.get_children():
		child.queue_free()

	# Look up the player by group (faster than hardcoding scene paths).
	var player: CharacterBody2D = GameManager.get_player()
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

		label.text = "[%d] %s (%s mana)\n    %s" % [i + 1, card.card_name, cost_str, card.description]

		if can_afford:
			label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		else:
			label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.6))

		card_details.add_child(label)

func _on_resume() -> void:
	# Delegate actual pause state changes to centralized game manager.
	GameManager.toggle_pause()

func _on_quit() -> void:
	# Exiting pause before changing scene avoids getting stuck in paused game state.
	get_tree().paused = false
	GameManager.go_to_class_select()
