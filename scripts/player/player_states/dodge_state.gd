extends PlayerState

var dodge_timer: float = 0.0

## Dodge state: short burst movement + temporary invincibility.

func enter() -> void:
	# Start dodge and prevent immediate chain-dodge.
	dodge_timer = player.dodge_duration
	player.can_dodge = false
	player.set_invincible(true)
	player.play_anim(&"dodge")
	player.clear_tracked_fx(PlayerController.DODGE_AFTERIMAGE_FX_TAG)

	# Dodge in movement direction if moving, otherwise toward mouse
	var dodge_dir: Vector2
	if player.has_move_intent():
		dodge_dir = player.get_move_direction()
	else:
		dodge_dir = player.get_aim_direction()
	player.velocity = dodge_dir * player.dodge_speed

	# Visual feedback: semi-transparent during dodge
	player.modulate.a = 0.5

	# Spawn afterimage ghosts
	_spawn_afterimages()

func physics_update(delta: float) -> void:
	# Keep moving during dodge then slow to stop.
	player.move_and_slide()
	player.report_motion_step(delta)
	# Decelerate
	player.velocity = player.velocity.lerp(Vector2.ZERO, 5.0 * delta)

	dodge_timer -= delta
	if dodge_timer <= 0.0:
		if state_machine.consume_attack_buffer():
			state_machine.transition_to("attack")
		elif player.can_dodge and state_machine.consume_dodge_buffer():
			state_machine.transition_to("dodge")
		elif player.has_move_intent():
			state_machine.transition_to("move")
		else:
			state_machine.transition_to("idle")

func _spawn_afterimages() -> void:
	var parent: Node = player.get_parent()
	if parent == null:
		return
	if player.anim_sprite == null or player.anim_sprite.sprite_frames == null:
		return

	for i in range(3):
		# Stagger ghost spawns across the dodge
		var delay := float(i) * player.dodge_duration * 0.25

		var tree: SceneTree = player.get_tree()
		if tree == null:
			return
		var timer: SceneTreeTimer = tree.create_timer(delay)
		timer.timeout.connect(func() -> void:
			if not is_instance_valid(player) or not is_instance_valid(parent):
				return
			if player.anim_sprite == null or player.anim_sprite.sprite_frames == null:
				return

			var ghost := Sprite2D.new()
			ghost.process_mode = Node.PROCESS_MODE_ALWAYS
			ghost.set_as_top_level(true)
			ghost.texture = player.anim_sprite.sprite_frames.get_frame_texture(
				player.anim_sprite.animation, player.anim_sprite.frame
			)
			if ghost.texture == null:
				ghost.queue_free()
				return
			ghost.set_meta("fx_owner_id", player.get_instance_id())
			ghost.set_meta("fx_tag", PlayerController.DODGE_AFTERIMAGE_FX_TAG)
			ghost.set_meta("fx_source", "dodge")
			ghost.global_position = player.global_position
			ghost.rotation = player.anim_sprite.rotation
			ghost.offset = player.anim_sprite.offset
			ghost.modulate = Color(0.5, 0.7, 1.0, 0.35)
			ghost.z_index = -1
			ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			parent.add_child(ghost)

			var tween: Tween = ghost.create_tween()
			tween.tween_property(ghost, "modulate:a", 0.0, 0.25).set_ease(Tween.EASE_IN)
			tween.tween_callback(ghost.queue_free)

			var cleanup_timer: SceneTreeTimer = tree.create_timer(0.35, true, false, true)
			cleanup_timer.timeout.connect(func() -> void:
				if is_instance_valid(ghost):
					ghost.queue_free()
			)
		)

func exit() -> void:
	# Restore normal collision and start cooldown timer in player component.
	player.set_invincible(false)
	player.modulate.a = 1.0
	player.clear_tracked_fx(PlayerController.DODGE_AFTERIMAGE_FX_TAG)
	# Start dodge cooldown
	player.start_dodge_cooldown()
