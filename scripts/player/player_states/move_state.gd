extends PlayerState

func physics_update(_delta: float) -> void:
	var iso_dir: Vector2 = player.get_iso_input()
	if iso_dir == Vector2.ZERO:
		state_machine.transition_to("idle")
		return

	player.velocity = iso_dir * player.move_speed
	player.update_facing(iso_dir)
	player.move_and_slide()

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("basic_attack"):
		state_machine.transition_to("attack")
	elif event.is_action_pressed("dodge") and player.can_dodge:
		state_machine.transition_to("dodge")
