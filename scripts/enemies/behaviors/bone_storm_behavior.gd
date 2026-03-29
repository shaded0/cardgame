class_name BoneStormBehavior
extends Node

## Bone Colossus: channels a bone storm with orbiting projectiles.

var storm_interval_min: float = 12.0
var storm_interval_max: float = 15.0
var channel_duration: float = 2.0
var projectile_damage: float = 6.0
var projectile_count: int = 4
var orbit_start_radius: float = 30.0
var orbit_end_radius: float = 100.0

var _next_storm_time: float = 6.0
var _is_channeling: bool = false
var _channel_timer: float = 0.0
var _projectiles: Array[Area2D] = []

func _process(delta: float) -> void:
	var enemy = get_parent()
	if enemy == null or not is_instance_valid(enemy):
		return
	if enemy.current_state == enemy.State.DEAD:
		_cancel_storm()
		return

	if _is_channeling:
		_channel_timer -= delta
		if _channel_timer <= 0.0:
			_end_storm(enemy)
		return

	_next_storm_time -= delta
	if _next_storm_time <= 0.0 and enemy.current_state == enemy.State.CHASE:
		_start_storm(enemy)

func before_physics(enemy: CharacterBody2D, _delta: float) -> bool:
	if not _is_channeling:
		return false

	enemy.velocity = Vector2.ZERO
	enemy._play_anim(&"attack")
	return true

func _start_storm(enemy: CharacterBody2D) -> void:
	_is_channeling = true
	_channel_timer = channel_duration
	_next_storm_time = randf_range(storm_interval_min, storm_interval_max)

	DamageNumber.spawn_text(enemy.get_parent(), enemy.global_position + Vector2(0, -40), "BONE STORM!", Color(0.8, 0.75, 0.5))
	ScreenFX.shake(enemy, 6.0, 0.2)

	var parent: Node = enemy.get_parent()
	if parent == null:
		return

	# Spawn orbiting bone projectiles
	for i in range(projectile_count):
		var proj := _create_bone_projectile()
		parent.add_child(proj)
		_projectiles.append(proj)

		# Orbit tween — each projectile starts at different angle
		var start_angle: float = float(i) / float(projectile_count) * TAU
		var orbit_tween := proj.create_tween()
		orbit_tween.set_loops(1)

		# Animate orbit: expand outward while rotating
		var steps: int = 20
		var step_duration: float = channel_duration / float(steps)
		for step in range(steps):
			var t: float = float(step) / float(steps)
			var angle: float = start_angle + t * TAU * 2.0  # 2 full rotations
			var radius: float = lerpf(orbit_start_radius, orbit_end_radius, t)
			var offset := Vector2(cos(angle), sin(angle)) * radius

			orbit_tween.tween_callback(func() -> void:
				if is_instance_valid(proj) and is_instance_valid(enemy):
					proj.global_position = enemy.global_position + offset
			)
			orbit_tween.tween_interval(step_duration)

func _end_storm(enemy: CharacterBody2D) -> void:
	_is_channeling = false

	# Fling projectiles outward then remove
	for proj in _projectiles:
		if is_instance_valid(proj) and is_instance_valid(enemy):
			var dir: Vector2 = (proj.global_position - enemy.global_position).normalized()
			var target: Vector2 = proj.global_position + dir * 200.0
			var tween := proj.create_tween()
			tween.tween_property(proj, "global_position", target, 0.5)
			tween.tween_callback(proj.queue_free)

	_projectiles.clear()

func _cancel_storm() -> void:
	_is_channeling = false
	_channel_timer = 0.0
	for proj in _projectiles:
		if is_instance_valid(proj):
			proj.queue_free()
	_projectiles.clear()

func _create_bone_projectile() -> Area2D:
	var proj := Area2D.new()
	proj.collision_layer = 0
	proj.collision_mask = 0

	var hitbox := Hitbox.new()
	hitbox.damage = projectile_damage
	hitbox.one_shot = false  # Can hit multiple times as it orbits
	hitbox.collision_layer = 64
	hitbox.collision_mask = 16
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 6.0
	shape.shape = circle
	hitbox.add_child(shape)
	proj.add_child(hitbox)

	# Visual — bone-colored circle
	var sprite := Sprite2D.new()
	sprite.texture = PlaceholderSprites.create_circle_texture(6, Color(0.85, 0.8, 0.65, 0.9))
	proj.add_child(sprite)

	# Trail
	var trail := Line2D.new()
	trail.width = 2.0
	trail.default_color = Color(0.7, 0.65, 0.5, 0.4)
	trail.add_point(Vector2.ZERO)
	trail.add_point(Vector2(-6, 0))
	proj.add_child(trail)

	return proj
