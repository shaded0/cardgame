extends Node

signal game_paused
signal game_resumed

var current_class_config: Resource = null

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause() -> void:
	var tree := get_tree()
	tree.paused = !tree.paused
	if tree.paused:
		game_paused.emit()
	else:
		game_resumed.emit()
