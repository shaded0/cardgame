extends "res://tests/support/test_case.gd"

const Factory = preload("res://tests/support/test_factory.gd")

func test_entering_a_rest_room_marks_it_complete_and_resets_carry_health() -> void:
	var manager = Factory.make_game_manager(root)
	manager.player_health_carry = 27.0
	var rest_room = Factory.make_room("rest", 1, [], RoomData.RoomType.REST)

	var completed: Array[String] = []
	manager.room_completed.connect(func(room_id: String) -> void:
		completed.append(room_id)
	)

	manager.enter_room(rest_room)

	assert_eq(manager.current_room, rest_room, "Entering a room should update current_room.")
	assert_eq(manager.player_health_carry, -1.0, "Rest rooms should reset carry health for a full heal.")
	assert_eq(manager.completed_rooms, ["rest"], "Rest rooms should be completed immediately.")
	assert_eq(completed, ["rest"], "Entering a rest room should emit room_completed once.")

func test_room_availability_respects_tiers_connections_and_completed_rooms() -> void:
	var manager = Factory.make_game_manager(root)
	var entrance = Factory.make_room("entrance", 0, ["hall"])
	var hall = Factory.make_room("hall", 1, ["boss"])
	var boss = Factory.make_room("boss", 2, [], RoomData.RoomType.BOSS)
	manager.all_rooms = [entrance, hall, boss]

	assert_true(manager.is_room_available(entrance), "Tier-zero rooms should be available at the start of a run.")
	assert_false(manager.is_room_available(hall), "Higher-tier rooms should stay locked until a connected room is completed.")

	manager.complete_room("entrance")

	assert_true(manager.is_room_available(hall), "A room should unlock once a completed room connects to it.")
	assert_false(manager.is_room_available(entrance), "Completed rooms should no longer appear available.")

	manager.complete_room("hall")
	manager.complete_room("hall")

	assert_true(manager.is_room_available(boss), "Later rooms should unlock from completed upstream connections.")
	assert_eq(manager.completed_rooms, ["entrance", "hall"], "Completing the same room twice should not duplicate it.")

func test_start_new_run_resets_state_and_loads_room_resources() -> void:
	var manager = Factory.make_game_manager(root)
	manager.completed_rooms = ["old_room"]
	manager.player_health_carry = 12.0

	manager.start_new_run()

	assert_true(manager.run_active, "Starting a run should mark the run as active.")
	assert_eq(manager.completed_rooms.size(), 0, "Starting a run should clear completed room history.")
	assert_eq(manager.player_health_carry, -1.0, "Starting a run should reset carry health.")
	assert_eq(manager.all_rooms.size(), 7, "Starting a run should load the configured room resources.")
	assert_not_null(manager.get_room_by_id("entrance"), "Loaded rooms should be discoverable by room_id.")
