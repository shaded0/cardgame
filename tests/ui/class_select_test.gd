extends "res://tests/support/test_case.gd"

const ClassSelectScene = preload("res://scenes/ui/class_select.tscn")

var _saved_config: ClassConfig = null
var _saved_run_active: bool = false

func before_each() -> void:
	_saved_config = GameManager.current_class_config
	_saved_run_active = GameManager.run_active

func after_each() -> void:
	GameManager.current_class_config = _saved_config
	GameManager.run_active = _saved_run_active

func test_class_select_ignores_repeat_selection_while_transitioning() -> void:
	var class_select: Control = ClassSelectScene.instantiate()
	root.add_child(class_select)

	class_select._select_class("res://resources/classes/soldier.tres")
	class_select._select_class("res://resources/classes/rogue.tres")

	var flash_count := 0
	for child in class_select.get_children():
		if child is ColorRect and child != class_select.get_node("Background"):
			flash_count += 1

	assert_eq(flash_count, 1, "Selecting a class twice quickly should only create one transition flash.")
	assert_eq(GameManager.current_class_config.class_id, &"soldier", "Once class selection starts, later clicks should not swap the chosen class mid-transition.")
