extends PlayerState

var attack_timer: float = 0.0

## Attack state: gate movement and rely on animation/animation-state timing.

func enter() -> void:
	# Attack duration is configurable in class data.
	attack_timer = player.attack_duration
	player.velocity = Vector2.ZERO
	if not player.start_attack():
		state_machine.call_deferred("recover_to_neutral")

func physics_update(delta: float) -> void:
	# Return to idle once hitbox window ends.
	attack_timer -= delta
	if attack_timer <= 0.0:
		player.end_attack()
		if state_machine.consume_attack_buffer():
			state_machine.transition_to("attack")
		elif player.can_dodge and state_machine.consume_dodge_buffer():
			state_machine.transition_to("dodge")
		elif player.get_iso_input() != Vector2.ZERO:
			state_machine.transition_to("move")
		else:
			state_machine.transition_to("idle")

func exit() -> void:
	# Safety: ensure every exit resets attack visuals/hitbox.
	player.end_attack()
