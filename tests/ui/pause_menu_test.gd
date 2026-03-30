extends "res://tests/support/test_case.gd"

const PauseMenuScene = preload("res://scenes/ui/pause_menu.tscn")

func test_pause_menu_disconnects_global_pause_signals_on_exit() -> void:
	var pause_menu: Control = PauseMenuScene.instantiate()
	root.add_child(pause_menu)

	var paused_cb := Callable(pause_menu, "_on_game_paused")
	var resumed_cb := Callable(pause_menu, "_on_game_resumed")
	assert_true(GameManager.game_paused.is_connected(paused_cb), "Pause menu should subscribe to global pause events while active.")
	assert_true(GameManager.game_resumed.is_connected(resumed_cb), "Pause menu should subscribe to global resume events while active.")

	pause_menu.queue_free()
	root.propagate_notification(Node.NOTIFICATION_EXIT_TREE)

	assert_false(GameManager.game_paused.is_connected(paused_cb), "Pause menu should disconnect from global pause events when freed.")
	assert_false(GameManager.game_resumed.is_connected(resumed_cb), "Pause menu should disconnect from global resume events when freed.")
