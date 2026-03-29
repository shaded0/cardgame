extends PlayerState

## Idle state: decelerates to zero then waits for new input.
## Smooth braking instead of instant stop gives weight to the character.

var _did_squash: bool = false

func enter() -> void:
	player.play_anim(&"idle")
	_did_squash = false
	# Subtle squash on stop if we were moving fast
	if player.velocity.length() > player.move_speed * 0.3:
		_squash_stretch(Vector2(0.94, 1.08), 0.08)
		_did_squash = true

func physics_update(delta: float) -> void:
	if state_machine.consume_attack_buffer():
		state_machine.transition_to("attack")
		return
	if player.can_dodge and state_machine.consume_dodge_buffer():
		state_machine.transition_to("dodge")
		return

	# Start moving as soon as input arrives.
	var iso_dir: Vector2 = player.get_iso_input()
	if iso_dir != Vector2.ZERO:
		state_machine.transition_to("move")
		return

	# Decelerate smoothly to zero instead of instant stop
	if player.velocity.length() > 5.0:
		player.velocity = player.velocity.move_toward(Vector2.ZERO, player.deceleration * delta)
		player.move_and_slide()
	else:
		player.velocity = Vector2.ZERO

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
