extends PlayerState

## Move state: drive player by input vector with acceleration curves.
## Uses move_toward with higher decel when reversing direction for crisp turns.

var _was_moving: bool = false

func enter() -> void:
	player.play_anim(&"run")
	_was_moving = player.velocity.length() > 10.0
	# Subtle stretch on movement start
	if not _was_moving:
		_squash_stretch(Vector2(1.08, 0.94), 0.06)

func physics_update(delta: float) -> void:
	if state_machine.consume_attack_buffer():
		state_machine.transition_to("attack")
		return
	if player.can_dodge and state_machine.consume_dodge_buffer():
		state_machine.transition_to("dodge")
		return

	var iso_dir: Vector2 = player.get_iso_input()
	if iso_dir == Vector2.ZERO:
		state_machine.transition_to("idle")
		return

	var target_velocity: Vector2 = iso_dir * player.move_speed

	# Determine effective acceleration — use higher decel when turning against current velocity
	var accel: float = player.acceleration
	if player.velocity.length() > 10.0 and player.velocity.dot(iso_dir) < 0.0:
		# Reversing direction: brake faster for crisp turns
		accel = player.deceleration * player.turn_decel_multiplier

	player.velocity = player.velocity.move_toward(target_velocity, accel * delta)
	player.update_facing(iso_dir)
	player.move_and_slide()

func exit() -> void:
	_was_moving = false

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("basic_attack") and state_machine.consume_attack_buffer():
		state_machine.transition_to("attack")
	elif event.is_action_pressed("dodge") and player.can_dodge and state_machine.consume_dodge_buffer():
		state_machine.transition_to("dodge")

func _squash_stretch(target_scale: Vector2, duration: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(player.anim_sprite):
		return
	var tween := player.create_tween()
	tween.tween_property(player.anim_sprite, "scale", target_scale, duration * 0.4)
	tween.tween_property(player.anim_sprite, "scale", Vector2(1.0, 1.0), duration * 0.6).set_ease(Tween.EASE_OUT)
