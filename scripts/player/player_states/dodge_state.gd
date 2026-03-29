extends PlayerState

var dodge_timer: float = 0.0

func enter() -> void:
	dodge_timer = player.dodge_duration
	player.can_dodge = false
	player.set_invincible(true)

	# Burst in facing direction
	var dodge_dir: Vector2 = player.facing_direction
	if dodge_dir == Vector2.ZERO:
		dodge_dir = Vector2.RIGHT
	player.velocity = dodge_dir * player.dodge_speed

	# Visual feedback: semi-transparent during dodge
	player.modulate.a = 0.5

func physics_update(delta: float) -> void:
	player.move_and_slide()
	# Decelerate
	player.velocity = player.velocity.lerp(Vector2.ZERO, 5.0 * delta)

	dodge_timer -= delta
	if dodge_timer <= 0.0:
		state_machine.transition_to("idle")

func exit() -> void:
	player.set_invincible(false)
	player.modulate.a = 1.0
	# Start dodge cooldown
	player.start_dodge_cooldown()
