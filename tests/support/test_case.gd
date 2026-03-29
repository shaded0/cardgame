extends RefCounted

var tree: SceneTree
var root: Node

var _current_test_name := ""
var _failures: Array[String] = []

func set_context(p_tree: SceneTree, p_root: Node) -> void:
	tree = p_tree
	root = p_root

func begin_test(test_name: String) -> void:
	_current_test_name = test_name
	_failures.clear()

func before_each() -> void:
	pass

func after_each() -> void:
	pass

func get_failures() -> Array[String]:
	return _failures.duplicate()

func fail(message: String) -> void:
	_failures.append(message)

func assert_true(condition: bool, message: String = "Expected condition to be true.") -> void:
	if not condition:
		fail(message)

func assert_false(condition: bool, message: String = "Expected condition to be false.") -> void:
	if condition:
		fail(message)

func assert_eq(actual, expected, message: String = "") -> void:
	if actual != expected:
		if message.is_empty():
			message = "Expected %s but got %s." % [str(expected), str(actual)]
		fail(message)

func assert_near(actual: float, expected: float, tolerance: float = 0.001, message: String = "") -> void:
	if abs(actual - expected) > tolerance:
		if message.is_empty():
			message = "Expected %.4f +/- %.4f but got %.4f." % [expected, tolerance, actual]
		fail(message)

func assert_not_null(value, message: String = "Expected value to be non-null.") -> void:
	if value == null:
		fail(message)

func assert_contains(container, value, message: String = "") -> void:
	if not (value in container):
		if message.is_empty():
			message = "Expected %s to contain %s." % [str(container), str(value)]
		fail(message)
