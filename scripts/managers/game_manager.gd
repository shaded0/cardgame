extends Node

signal game_paused
signal game_resumed
signal room_completed(room_id: String)

## Game-wide state: pause, class selection, and run progression.

const MAP_SCENE_PATH := "res://scenes/map/map.tscn"
const CLASS_SELECT_SCENE_PATH := "res://scenes/ui/class_select.tscn"

var current_class_config: ClassConfig = null
var current_room: RoomData = null

# Run state
var run_active: bool = false
var completed_rooms: Array[String] = []
var player_health_carry: float = -1.0  ## -1 means use max_health
var run_deck: Array[CardData] = []     ## Cards accumulated during the run

# All rooms loaded at run start
var all_rooms: Array[RoomData] = []
var debug_attack_logging: bool = true

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

func get_player() -> PlayerController:
	return _get_first_node_in_group(&"player") as PlayerController

func get_enemies() -> Array[Node]:
	return get_tree().get_nodes_in_group(&"enemies")

func go_to_map() -> void:
	_change_scene(MAP_SCENE_PATH)

func go_to_class_select() -> void:
	_change_scene(CLASS_SELECT_SCENE_PATH)

func start_new_run() -> void:
	run_active = true
	current_room = null
	completed_rooms.clear()
	player_health_carry = -1.0
	run_deck = current_class_config.card_pool.duplicate() if current_class_config else []
	_load_all_rooms()

const MIN_DECK_SIZE: int = 4

func add_card_to_deck(card: CardData) -> void:
	run_deck.append(card)

func remove_card_from_deck(deck_index: int) -> bool:
	if run_deck.size() <= MIN_DECK_SIZE:
		return false
	if deck_index < 0 or deck_index >= run_deck.size():
		return false
	run_deck.remove_at(deck_index)
	return true

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
		var room: RoomData = load(path) as RoomData
		if room:
			all_rooms.append(room)

func complete_room(room_id: String) -> void:
	if room_id in completed_rooms:
		return
	completed_rooms.append(room_id)
	room_completed.emit(room_id)

func is_room_available(room: RoomData) -> bool:
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

func get_room_by_id(room_id: String) -> RoomData:
	for room in all_rooms:
		if room.room_id == room_id:
			return room
	return null

func enter_room(room: RoomData) -> void:
	current_room = room
	if room.room_type == RoomData.RoomType.REST:
		player_health_carry = -1.0  # Full heal
		complete_room(room.room_id)
	else:
		_change_scene(room.arena_scene_path)

func _get_first_node_in_group(group_name: StringName) -> Node:
	var nodes: Array[Node] = get_tree().get_nodes_in_group(group_name)
	if nodes.is_empty():
		return null
	return nodes[0]

var _transitioning: bool = false
var _pending_scene_path: String = ""

func _change_scene(path: String) -> void:
	var tree := get_tree()
	if tree.paused:
		tree.paused = false
		game_resumed.emit()

	_pending_scene_path = path
	if _transitioning:
		return

	_transitioning = true

	# Fade to black, switch scenes, then fade back in. Keep listening for
	# redirects during the transition so quick menu actions do not get dropped.
	var layer := CanvasLayer.new()
	layer.layer = 100
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)

	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.color = Color(0, 0, 0, 0)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)

	while true:
		if rect.color.a < 1.0:
			var fade_out := create_tween()
			fade_out.tween_property(rect, "color:a", 1.0, 0.2).set_ease(Tween.EASE_IN)
			await fade_out.finished

		while not _pending_scene_path.is_empty():
			var next_path := _pending_scene_path
			_pending_scene_path = ""
			tree.change_scene_to_file(next_path)
			# Wait a frame for the new scene to load before applying any queued redirect.
			await tree.process_frame

		var fade_in := create_tween()
		fade_in.tween_property(rect, "color:a", 0.0, 0.25).set_ease(Tween.EASE_OUT)
		await fade_in.finished

		if _pending_scene_path.is_empty():
			break

	layer.queue_free()
	_transitioning = false

func log_attack(source: String, event: String, details: Dictionary = {}) -> void:
	if not debug_attack_logging or not OS.is_debug_build():
		return

	var detail_text := ""
	for key in details.keys():
		if not detail_text.is_empty():
			detail_text += ", "
		detail_text += "%s=%s" % [str(key), str(details[key])]

	if not detail_text.is_empty():
		detail_text = " | " + detail_text

	print("[ATTACK][%s][%d] %s%s" % [source, Time.get_ticks_msec(), event, detail_text])
