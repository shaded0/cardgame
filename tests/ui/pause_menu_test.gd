extends "res://tests/support/test_case.gd"

const PauseMenuScene = preload("res://scenes/ui/pause_menu.tscn")

var _saved_transitioning := false
var _saved_pending_scene_path := ""

func before_each() -> void:
	_saved_transitioning = GameManager._transitioning
	_saved_pending_scene_path = GameManager._pending_scene_path

func after_each() -> void:
	tree.paused = false
	GameManager._transitioning = _saved_transitioning
	GameManager._pending_scene_path = _saved_pending_scene_path
	for child in GameManager.get_children():
		child.free()

func test_pause_menu_processes_during_pause_and_resume_transition() -> void:
	var pause_menu: Control = PauseMenuScene.instantiate()
	root.add_child(pause_menu)

	assert_eq(
		pause_menu.process_mode,
		Node.PROCESS_MODE_ALWAYS,
		"Pause menu should keep processing after unpause so its close tween can hide the overlay."
	)

func test_pause_menu_starts_hidden_and_shows_when_paused() -> void:
	var pause_menu: Control = PauseMenuScene.instantiate()
	root.add_child(pause_menu)

	assert_false(pause_menu.visible, "Pause menu should start hidden before the game is paused.")

	pause_menu._on_game_paused()

	assert_true(pause_menu.visible, "Pause menu should become visible when pause handling runs.")

func test_pause_menu_resume_unpauses_tree_and_emits_resume_signal() -> void:
	var pause_menu: Control = PauseMenuScene.instantiate()
	root.add_child(pause_menu)

	var resumed_count := 0
	GameManager.game_resumed.connect(func() -> void:
		resumed_count += 1
	, CONNECT_ONE_SHOT)

	tree.paused = true
	pause_menu._on_resume()

	assert_false(tree.paused, "Resuming from the pause menu should unpause the scene tree.")
	assert_eq(resumed_count, 1, "Resuming from the pause menu should emit game_resumed once.")

func test_pause_menu_resume_button_triggers_resume_handler() -> void:
	var pause_menu: Control = PauseMenuScene.instantiate()
	root.add_child(pause_menu)

	var resumed_count := 0
	GameManager.game_resumed.connect(func() -> void:
		resumed_count += 1
	, CONNECT_ONE_SHOT)

	tree.paused = true
	var resume_button: Button = pause_menu.get_node("Panel/VBoxContainer/ResumeButton")
	resume_button.emit_signal("pressed")

	assert_false(tree.paused, "Pressing the Resume button should unpause the scene tree.")
	assert_eq(resumed_count, 1, "Pressing the Resume button should route through the same resume flow.")

func test_pause_menu_disconnects_global_pause_signals_on_exit() -> void:
	var pause_menu: Control = PauseMenuScene.instantiate()
	root.add_child(pause_menu)

	var paused_cb := Callable(pause_menu, "_on_game_paused")
	var resumed_cb := Callable(pause_menu, "_on_game_resumed")
	assert_true(GameManager.game_paused.is_connected(paused_cb), "Pause menu should subscribe to global pause events while active.")
	assert_true(GameManager.game_resumed.is_connected(resumed_cb), "Pause menu should subscribe to global resume events while active.")

	pause_menu.queue_free()
	await tree.process_frame

	assert_false(GameManager.game_paused.is_connected(paused_cb), "Pause menu should disconnect from global pause events when freed.")
	assert_false(GameManager.game_resumed.is_connected(resumed_cb), "Pause menu should disconnect from global resume events when freed.")

func test_pause_menu_quit_uses_game_manager_resume_path() -> void:
	var pause_menu: Control = PauseMenuScene.instantiate()
	root.add_child(pause_menu)

	var resumed_count := 0
	GameManager.game_resumed.connect(func() -> void:
		resumed_count += 1
	, CONNECT_ONE_SHOT)

	tree.paused = true
	pause_menu._on_quit()

	assert_false(tree.paused, "Quitting from the pause menu should still unpause the tree before changing scenes.")
	assert_eq(resumed_count, 1, "Quitting from pause should emit game_resumed through GameManager so other pause listeners can clean up.")
	assert_eq(GameManager._pending_scene_path, GameManager.CLASS_SELECT_SCENE_PATH, "Quitting from pause should queue the class-select scene transition.")

func test_pause_menu_quit_button_routes_to_class_select_transition() -> void:
	var pause_menu: Control = PauseMenuScene.instantiate()
	root.add_child(pause_menu)

	tree.paused = true
	var quit_button: Button = pause_menu.get_node("Panel/VBoxContainer/QuitButton")
	quit_button.emit_signal("pressed")

	assert_false(tree.paused, "Pressing Quit to Menu should unpause the scene tree before changing scenes.")
	assert_eq(GameManager._pending_scene_path, GameManager.CLASS_SELECT_SCENE_PATH, "Pressing Quit to Menu should route through the class-select transition flow.")
