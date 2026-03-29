extends BaseAttack

## Slow long-range magic bolt

const PROJECTILE_SPEED: float = 180.0
const PROJECTILE_RANGE: float = 400.0
const PROJECTILE_LIFETIME: float = 2.2

func execute(player: CharacterBody2D, direction: Vector2) -> void:
	_spawn_bolt(player, direction)

func _spawn_bolt(player: CharacterBody2D, direction: Vector2) -> void:
	var projectile := Area2D.new()
	projectile.collision_layer = 4
	projectile.collision_mask = 32
	projectile.global_position = player.global_position + direction * 8.0

	# Glowing magic bolt
	var sprite := Sprite2D.new()
	sprite.texture = PlaceholderSprites.create_circle_texture(4, Color(0.6, 0.3, 1.0, 0.9))
	projectile.add_child(sprite)

	# Glow aura behind it
	var glow := Sprite2D.new()
	glow.texture = PlaceholderSprites.create_circle_texture(6, Color(0.5, 0.2, 0.8, 0.25))
	glow.z_index = -1
	projectile.add_child(glow)

	# Trail
	var trail := Line2D.new()
	trail.width = 2.0
	trail.default_color = Color(0.6, 0.3, 1.0, 0.3)
	trail.add_point(Vector2.ZERO)
	trail.add_point(-direction * 10.0)
	projectile.add_child(trail)

	# Collision
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	shape.shape = circle
	projectile.add_child(shape)

	# Hitbox
	var hitbox_script: Script = load("res://scripts/combat/hitbox.gd")
	projectile.set_script(hitbox_script)
	projectile.damage = player.attack_damage

	player.get_parent().add_child(projectile)

	# Pulse the glow
	var glow_tween: Tween = glow.create_tween().set_loops()
	glow_tween.tween_property(glow, "scale", Vector2(1.3, 1.3), 0.3)
	glow_tween.tween_property(glow, "scale", Vector2(1.0, 1.0), 0.3)

	# Movement
	var dir: Vector2 = direction.normalized()
	var tween: Tween = projectile.create_tween()
	var end_pos: Vector2 = projectile.global_position + dir * PROJECTILE_RANGE
	tween.tween_property(projectile, "global_position", end_pos, PROJECTILE_LIFETIME)
	tween.tween_callback(projectile.queue_free)

func get_attack_duration() -> float:
	return 0.8
