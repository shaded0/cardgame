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

	# Visible knife sprite
	var sprite := Sprite2D.new()
	sprite.texture = PlaceholderSprites.create_rect_texture(6, 3, Color(0.7, 1.0, 0.7, 0.9))
	sprite.rotation = direction.angle()
	projectile.add_child(sprite)

	# Trail effect
	var trail := Line2D.new()
	trail.width = 1.5
	trail.default_color = Color(0.5, 1.0, 0.5, 0.4)
	trail.add_point(Vector2.ZERO)
	trail.add_point(-direction * 6.0)
	projectile.add_child(trail)

	# Collision
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	shape.shape = circle
	projectile.add_child(shape)

	# Hitbox script
	var hitbox_script: Script = load("res://scripts/combat/hitbox.gd")
	projectile.set_script(hitbox_script)
	projectile.damage = player.attack_damage

	var dir: Vector2 = direction.normalized()
	player.get_parent().add_child(projectile)

	var tween: Tween = projectile.create_tween()
	var end_pos: Vector2 = projectile.global_position + dir * PROJECTILE_RANGE
	tween.tween_property(projectile, "global_position", end_pos, PROJECTILE_LIFETIME)
	tween.tween_callback(projectile.queue_free)

func get_attack_duration() -> float:
	return 0.25
