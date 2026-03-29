extends PlayerState

## Idle state: zero velocity + ready for new input.

func enter() -> void:
	# Always clear velocity when fully idling.
	player.velocity = Vector2.ZERO
	player.play_anim(&"idle")

func physics_update(_delta: float) -> void:
	# Start moving as soon as input arrives.
	var iso_dir: Vector2 = player.get_iso_input()
	if iso_dir != Vector2.ZERO:
		state_machine.transition_to("move")
		return

func handle_input(event: InputEvent) -> void:
	# Attack/dodge should always be processed even from idle.
	if event.is_action_pressed("basic_attack"):
		state_machine.transition_to("attack")
	elif event.is_action_pressed("dodge") and player.can_dodge:
		state_machine.transition_to("dodge")
