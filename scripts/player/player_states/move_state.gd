extends PlayerState

## Move state: drive player by input vector and animate running.

func enter() -> void:
	# Entering move state begins running animation.
	player.play_anim(&"run")

func physics_update(_delta: float) -> void:
	if state_machine.consume_attack_buffer():
		state_machine.transition_to("attack")
		return
	if player.can_dodge and state_machine.consume_dodge_buffer():
		state_machine.transition_to("dodge")
		return

	# Query isometric input from player node and switch back if no movement input.
	var iso_dir: Vector2 = player.get_iso_input()
	if iso_dir == Vector2.ZERO:
		state_machine.transition_to("idle")
		return

	player.velocity = iso_dir * player.move_speed
	player.update_facing(iso_dir)
	player.move_and_slide()

func handle_input(event: InputEvent) -> void:
	# Input can interrupt move state for attack/dodge actions.
	if event.is_action_pressed("basic_attack") and state_machine.consume_attack_buffer():
		state_machine.transition_to("attack")
	elif event.is_action_pressed("dodge") and player.can_dodge and state_machine.consume_dodge_buffer():
		state_machine.transition_to("dodge")
