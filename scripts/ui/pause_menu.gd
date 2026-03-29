extends Control

## Pause menu — visible when game is paused.
## process_mode = PROCESS_MODE_WHEN_PAUSED so it receives input while tree is paused.

@onready var card_details: VBoxContainer = $Panel/VBoxContainer/CardDetails
@onready var resume_btn: Button = $Panel/VBoxContainer/ResumeButton
@onready var quit_btn: Button = $Panel/VBoxContainer/QuitButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	resume_btn.pressed.connect(_on_resume)
	quit_btn.pressed.connect(_on_quit)

	GameManager.game_paused.connect(_on_game_paused)
	GameManager.game_resumed.connect(_on_game_resumed)

func _on_game_paused() -> void:
	visible = true
	_populate_card_details()
	resume_btn.grab_focus()

func _on_game_resumed() -> void:
	visible = false

func _populate_card_details() -> void:
	# Clear existing card info
	for child in card_details.get_children():
		child.queue_free()

	# Find player and show current hand
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return

	var player: CharacterBody2D = players[0]
	var card_mgr: CardManager = player.get_node("CardManager")

	for i in range(card_mgr.hand.size()):
		var card = card_mgr.hand[i]
		if card == null:
			continue

		var label := Label.new()
		label.add_theme_font_size_override("font_size", 6)
		label.text = "[%d] %s (%d) - %s" % [i + 1, card.card_name, card.mana_cost, card.description]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		card_details.add_child(label)

func _on_resume() -> void:
	GameManager.toggle_pause()

func _on_quit() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/class_select.tscn")
