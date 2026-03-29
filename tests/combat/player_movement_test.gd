extends "res://tests/support/test_case.gd"

const Factory = preload("res://tests/support/test_factory.gd")

func test_move_intent_grace_survives_brief_input_release() -> void:
	var player := Factory.make_player_controller(root)

	player.set_movement_input_override(Vector2.RIGHT)
	player.update_movement_input(0.0)
	assert_true(player.has_move_intent(), "Non-zero movement input should register move intent immediately.")

	player.set_movement_input_override(Vector2.ZERO)
	player.update_movement_input(player.move_intent_grace * 0.5)

	assert_true(player.has_move_intent(), "Brief release gaps should preserve move intent during the grace window.")
	assert_true(player.get_move_direction().dot(player.get_last_move_direction()) > 0.99, "Grace handling should preserve the last move direction.")

	player.update_movement_input(player.move_intent_grace + 0.01)

	assert_false(player.has_move_intent(), "Move intent should expire after the grace window elapses.")

func test_move_state_does_not_chatter_to_idle_on_single_brief_release() -> void:
	var player := Factory.make_player_controller(root)

	player.set_movement_input_override(Vector2.RIGHT)
	player.state_machine._physics_process(0.016)
	assert_eq(player.state_machine.current_state.name.to_lower(), "move", "Movement input should transition idle players into move.")

	player.set_movement_input_override(Vector2.ZERO)
	player.state_machine._physics_process(player.move_intent_grace * 0.5)
	assert_eq(player.state_machine.current_state.name.to_lower(), "move", "Brief input gaps should not immediately kick the player back to idle.")

	player.state_machine._physics_process(player.move_intent_grace + 0.02)
	assert_eq(player.state_machine.current_state.name.to_lower(), "idle", "Move state should still settle back to idle once input has been released long enough.")

func test_dodge_uses_recent_move_direction_during_grace_window() -> void:
	var player := Factory.make_player_controller(root)

	player.set_movement_input_override(Vector2.UP)
	player.update_movement_input(0.0)
	var expected_dir := player.get_move_direction()

	player.set_movement_input_override(Vector2.ZERO)
	player.update_movement_input(player.move_intent_grace * 0.5)
	player.state_machine.transition_to("dodge")

	assert_true(player.velocity.normalized().dot(expected_dir) > 0.99, "Dodges should honor recent movement intent instead of snapping to mouse aim on tiny release gaps.")

func test_compute_unstuck_direction_prefers_collision_normals() -> void:
	var dir := PlayerController.compute_unstuck_direction([Vector2.LEFT, Vector2.LEFT], Vector2.RIGHT)

	assert_true(dir.dot(Vector2.LEFT) > 0.99, "Unstuck direction should follow the blocking collision normals when they are available.")

func test_compute_unstuck_direction_falls_back_to_backing_off_move_direction() -> void:
	var dir := PlayerController.compute_unstuck_direction([], Vector2.UP)

	assert_true(dir.dot(Vector2.DOWN) > 0.99, "Without collision normals, unstuck direction should back the player away from their stuck move direction.")
