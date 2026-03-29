extends Node

signal game_paused
signal game_resumed
signal room_completed(room_id: String)

## Game-wide state: pause, class selection, and run progression.

var current_class_config: Resource = null
var current_room: Resource = null  ## RoomData

# Run state
var run_active: bool = false
var completed_rooms: Array[String] = []
var player_health_carry: float = -1.0  ## -1 means use max_health

# All rooms loaded at run start
var all_rooms: Array[Resource] = []

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

func start_new_run() -> void:
	run_active = true
	completed_rooms.clear()
	player_health_carry = -1.0
	_load_all_rooms()

func _load_all_rooms() -> void:
	all_rooms.clear()
	var room_paths: Array[String] = [
		"res://resources/rooms/entrance.tres",
		"res://resources/rooms/dark_corridor.tres",
		"res://resources/rooms/armory.tres",
		"res://resources/rooms/rest_chamber.tres",
		"res://resources/rooms/dungeon_depths.tres",
		"res://resources/rooms/trapped_hall.tres",
		"res://resources/rooms/boss_chamber.tres",
	]
	for path in room_paths:
		var room: Resource = load(path)
		if room:
			all_rooms.append(room)

func complete_room(room_id: String) -> void:
	if room_id not in completed_rooms:
		completed_rooms.append(room_id)
	room_completed.emit(room_id)

func is_room_available(room: Resource) -> bool:
	var room_id: String = room.room_id
	if room_id in completed_rooms:
		return false
	# First tier always available
	if room.tier == 0:
		return true
	# Available if any room connecting TO this room is completed
	for other in all_rooms:
		if room_id in other.connections and other.room_id in completed_rooms:
			return true
	return false

func get_room_by_id(room_id: String) -> Resource:
	for room in all_rooms:
		if room.room_id == room_id:
			return room
	return null

func enter_room(room: Resource) -> void:
	current_room = room
	if room.room_type == 2:  # REST
		player_health_carry = -1.0  # Full heal
		complete_room(room.room_id)
	else:
		get_tree().change_scene_to_file(room.arena_scene_path)
