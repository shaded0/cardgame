extends "res://tests/support/test_case.gd"

const Factory = preload("res://tests/support/test_factory.gd")
const MapScreenScript = preload("res://scripts/map/map_screen.gd")

var _saved_run_active: bool = false
var _saved_all_rooms: Array[RoomData] = []
var _saved_completed_rooms: Array[String] = []

func before_each() -> void:
	_saved_run_active = GameManager.run_active
	_saved_all_rooms = GameManager.all_rooms.duplicate()
	_saved_completed_rooms = GameManager.completed_rooms.duplicate()

func after_each() -> void:
	GameManager.run_active = _saved_run_active
	GameManager.all_rooms = _saved_all_rooms.duplicate()
	GameManager.completed_rooms = _saved_completed_rooms.duplicate()

func test_build_map_reuses_a_single_line_container_on_refresh() -> void:
	GameManager.run_active = true
	GameManager.completed_rooms.clear()
	GameManager.all_rooms = [
		Factory.make_room("entrance", 0, ["hall"]),
		Factory.make_room("hall", 1, []),
	]

	var map_screen := MapScreenScript.new()
	root.add_child(map_screen)

	map_screen._build_map()

	var line_container_count := 0
	for child in map_screen.get_children():
		if child.name == "MapLines":
			line_container_count += 1

	assert_eq(line_container_count, 1, "Refreshing the map should keep a single MapLines container instead of stacking duplicate line layers.")

func test_map_screen_disconnects_room_completed_listener_on_exit() -> void:
	GameManager.run_active = true
	GameManager.all_rooms = [Factory.make_room("entrance", 0, [])]

	var map_screen := MapScreenScript.new()
	root.add_child(map_screen)

	var room_completed_cb := Callable(map_screen, "_on_room_completed")
	assert_true(GameManager.room_completed.is_connected(room_completed_cb), "Map screen should subscribe to room_completed while active.")

	map_screen.queue_free()
	root.propagate_notification(Node.NOTIFICATION_EXIT_TREE)

	assert_false(GameManager.room_completed.is_connected(room_completed_cb), "Map screen should disconnect from room_completed when leaving the tree.")
