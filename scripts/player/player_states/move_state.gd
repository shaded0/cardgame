extends PlayerState

## Move state: drive player by input vector with acceleration curves.
## Uses move_toward with higher decel when reversing direction for crisp turns.

var _was_moving: bool = false
var _prev_dir: Vector2 = Vector2.ZERO

func enter() -> void:
	_update_move_animation(1.0)
	_was_moving = player.velocity.length() > 10.0
	_prev_dir = player.velocity.normalized()
	# Subtle stretch on movement start + dust kick
	if not _was_moving:
		_squash_stretch(Vector2(1.08, 0.94), 0.06)
		var iso_dir: Vector2 = player.get_iso_input()
		ScreenFX.spawn_dust_puff(player.get_parent(), player.global_position, iso_dir, 2)

func physics_update(delta: float) -> void:
	if state_machine.consume_attack_buffer():
		state_machine.transition_to("attack")
		return
	if player.can_dodge and state_machine.consume_dodge_buffer():
		state_machine.transition_to("dodge")
		return

	if not player.has_move_intent():
		state_machine.transition_to("idle")
		return

	var iso_dir: Vector2 = player.get_move_direction()
	var input_strength: float = player.get_move_input_strength()
	if input_strength <= 0.0:
		# Briefly coast through tiny release gaps so movement doesn't chatter between move/idle.
		player.velocity = player.velocity.move_toward(Vector2.ZERO, player.deceleration * delta * 0.65)
		player.move_and_slide()
		return

	_update_move_animation(input_strength)
	var target_velocity: Vector2 = iso_dir * player.move_speed * input_strength

	# Determine effective acceleration — use higher decel when turning against current velocity
	var accel: float = player.acceleration
	var is_turning: bool = player.velocity.length() > 10.0 and player.velocity.dot(iso_dir) < 0.0
	if is_turning:
		# Reversing direction: brake faster for crisp turns + kick up dust
		accel = player.deceleration * player.turn_decel_multiplier
		if _prev_dir.dot(iso_dir) < -0.3:
			ScreenFX.spawn_dust_puff(player.get_parent(), player.global_position, iso_dir, 2)
			_prev_dir = iso_dir
	elif iso_dir.length() > 0.1:
		_prev_dir = iso_dir

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

func _update_move_animation(input_strength: float) -> void:
	player.play_anim(&"run" if input_strength >= 0.85 else &"walk")
