extends BaseAttack

## Fast mid-range knife projectile

const PROJECTILE_SPEED: float = 300.0
const PROJECTILE_RANGE: float = 200.0
const PROJECTILE_LIFETIME: float = 0.7

func execute(player: CharacterBody2D, direction: Vector2) -> void:
	_spawn_knife(player, direction)

func _spawn_knife(player: CharacterBody2D, direction: Vector2) -> void:
	var projectile := Area2D.new()
	projectile.collision_layer = 4
	projectile.collision_mask = 32
	projectile.global_position = player.global_position + direction * 10.0

	# Visual
	var sprite := Sprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Use a colored rect as placeholder
	projectile.add_child(sprite)

	# Collision
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	shape.shape = circle
	projectile.add_child(shape)

	# Hitbox script
	var hitbox_script = load("res://scripts/combat/hitbox.gd")
	projectile.set_script(hitbox_script)
	projectile.damage = player.attack_damage

	# Movement via script attached inline
	var dir := direction.normalized()
	projectile.set_meta("direction", dir)
	projectile.set_meta("speed", PROJECTILE_SPEED)
	projectile.set_meta("lifetime", PROJECTILE_LIFETIME)

	player.get_parent().add_child(projectile)

	# Animate movement with tween
	var tween := projectile.create_tween()
	var end_pos := projectile.global_position + dir * PROJECTILE_RANGE
	tween.tween_property(projectile, "global_position", end_pos, PROJECTILE_LIFETIME)
	tween.tween_callback(projectile.queue_free)

func get_attack_duration() -> float:
	return 0.25
