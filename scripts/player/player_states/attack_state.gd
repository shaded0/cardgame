extends PlayerState

var attack_timer: float = 0.0

## Attack state: gate movement and rely on animation/animation-state timing.

func enter() -> void:
	# Attack duration is configurable in class data.
	attack_timer = player.attack_duration
	player.velocity = Vector2.ZERO
	player.start_attack()

func physics_update(delta: float) -> void:
	# Return to idle once hitbox window ends.
	attack_timer -= delta
	if attack_timer <= 0.0:
		player.end_attack()
		state_machine.transition_to("idle")

func exit() -> void:
	# Safety: ensure every exit resets attack visuals/hitbox.
	player.end_attack()
