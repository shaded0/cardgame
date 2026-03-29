extends Control

## Pause menu — visible when game is paused.
## Cards can be played while paused using number keys.

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
	for child in card_details.get_children():
		child.queue_free()

	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return

	var player: CharacterBody2D = players[0] as CharacterBody2D
	var card_mgr: CardManager = player.get_node("CardManager")
	var mana_comp: ManaComponent = player.get_node("ManaComponent")

	# Hint text
	var hint := Label.new()
	hint.add_theme_font_size_override("font_size", 5)
	hint.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0, 0.8))
	hint.text = "Press 1-4 to play cards while paused"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_details.add_child(hint)

	for i in range(card_mgr.hand.size()):
		var card: Resource = card_mgr.hand[i]
		if card == null:
			continue

		var label := Label.new()
		label.add_theme_font_size_override("font_size", 6)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD

		var can_afford: bool = mana_comp.current_mana >= card.mana_cost
		var cost_str: String = str(card.mana_cost)

		label.text = "[%d] %s (%s mana)\n    %s" % [i + 1, card.card_name, cost_str, card.description]

		if can_afford:
			label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		else:
			label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.6))

		card_details.add_child(label)

func _on_resume() -> void:
	GameManager.toggle_pause()

func _on_quit() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/class_select.tscn")
