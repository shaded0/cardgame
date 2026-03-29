class_name PoisonTrailBehavior
extends Node

## Plague Rat behavior: drops poison puddles while chasing.

var puddle_cooldown_min: float = 3.0
var puddle_cooldown_max: float = 4.0
var puddle_radius: float = 20.0
var puddle_lifetime: float = 4.0

var _next_puddle_time: float = 2.0  # Initial delay

func _process(delta: float) -> void:
	var enemy = get_parent()
	if enemy == null or not is_instance_valid(enemy):
		return
	if enemy.current_state != enemy.State.CHASE:
		return

	_next_puddle_time -= delta
	if _next_puddle_time <= 0.0:
		_drop_puddle(enemy)
		_next_puddle_time = randf_range(puddle_cooldown_min, puddle_cooldown_max)

func _drop_puddle(enemy: CharacterBody2D) -> void:
	var parent: Node = enemy.get_parent()
	if parent == null:
		return

	var puddle := Area2D.new()
	puddle.global_position = enemy.global_position
	puddle.collision_layer = 0
	puddle.collision_mask = 0

	# Hitbox to detect player overlap
	var hitbox := Area2D.new()
	hitbox.collision_layer = 64  # Enemy projectile layer
	hitbox.collision_mask = 16   # Player hurtbox layer
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = puddle_radius
	shape.shape = circle
	hitbox.add_child(shape)
	puddle.add_child(hitbox)

	# Visual — green toxic puddle
	var sprite := Sprite2D.new()
	sprite.texture = PlaceholderSprites.create_circle_texture(int(puddle_radius), Color(0.3, 0.7, 0.1, 0.4))
	sprite.z_index = -1
	puddle.add_child(sprite)

	parent.add_child(puddle)

	# Pulse animation
	var pulse_tween := puddle.create_tween().set_loops(int(puddle_lifetime / 0.8))
	pulse_tween.tween_property(sprite, "modulate:a", 0.6, 0.4)
	pulse_tween.tween_property(sprite, "modulate:a", 0.3, 0.4)

	# Apply poison on overlap
	hitbox.body_entered.connect(func(body: Node2D) -> void:
		if not is_instance_valid(puddle):
			return
		if body.has_node("StatusEffectManager"):
			var sem: StatusEffectManager = body.get_node("StatusEffectManager")
			sem.apply_effect(StatusEffect.poison(2.0, 4.0))
	)

	# Fade and remove after lifetime
	var life_tween := puddle.create_tween()
	life_tween.tween_interval(puddle_lifetime - 0.5)
	life_tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	life_tween.tween_callback(puddle.queue_free)
