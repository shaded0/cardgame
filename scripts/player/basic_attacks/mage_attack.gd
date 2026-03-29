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

	# Visual placeholder
	var sprite := Sprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	projectile.add_child(sprite)

	# Collision
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	shape.shape = circle
	projectile.add_child(shape)

	# Hitbox
	var hitbox_script = load("res://scripts/combat/hitbox.gd")
	projectile.set_script(hitbox_script)
	projectile.damage = player.attack_damage

	player.get_parent().add_child(projectile)

	# Movement
	var dir := direction.normalized()
	var tween := projectile.create_tween()
	var end_pos := projectile.global_position + dir * PROJECTILE_RANGE
	tween.tween_property(projectile, "global_position", end_pos, PROJECTILE_LIFETIME)
	tween.tween_callback(projectile.queue_free)

func get_attack_duration() -> float:
	return 0.8
