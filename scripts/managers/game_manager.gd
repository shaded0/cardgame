extends Node

signal game_paused
signal game_resumed

## High-level game-wide state (small version).
## Kept intentionally minimal: pause toggling + selected class for cross-scene transfer.

var current_class_config: Resource = null

func _unhandled_input(event: InputEvent) -> void:
	# Global pause hotkey (works even if focus is on pause/menu or HUD).
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause() -> void:
	# Single source of truth for pausing so every system can subscribe to one event.
	var tree := get_tree()
	tree.paused = !tree.paused
	if tree.paused:
		game_paused.emit()
	else:
		game_resumed.emit()
