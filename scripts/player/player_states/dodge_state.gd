extends PlayerState

var dodge_timer: float = 0.0

## Dodge state: short burst movement + temporary invincibility.

func enter() -> void:
	# Start dodge and prevent immediate chain-dodge.
	dodge_timer = player.dodge_duration
	player.can_dodge = false
	player.set_invincible(true)
	player.play_anim(&"dodge")

	# Dodge in movement direction if moving, otherwise toward mouse
	var iso_input: Vector2 = player.get_iso_input()
	var dodge_dir: Vector2
	if iso_input != Vector2.ZERO:
		dodge_dir = iso_input
	else:
		dodge_dir = player.get_aim_direction()
	player.velocity = dodge_dir * player.dodge_speed

	# Visual feedback: semi-transparent during dodge
	player.modulate.a = 0.5

func physics_update(delta: float) -> void:
	# Keep moving during dodge then slow to stop.
	player.move_and_slide()
	# Decelerate
	player.velocity = player.velocity.lerp(Vector2.ZERO, 5.0 * delta)

	dodge_timer -= delta
	if dodge_timer <= 0.0:
		if state_machine.consume_attack_buffer():
			state_machine.transition_to("attack")
		elif player.can_dodge and state_machine.consume_dodge_buffer():
			state_machine.transition_to("dodge")
		elif player.get_iso_input() != Vector2.ZERO:
			state_machine.transition_to("move")
		else:
			state_machine.transition_to("idle")

func exit() -> void:
	# Restore normal collision and start cooldown timer in player component.
	player.set_invincible(false)
	player.modulate.a = 1.0
	# Start dodge cooldown
	player.start_dodge_cooldown()
