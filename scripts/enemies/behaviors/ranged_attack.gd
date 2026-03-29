class_name RangedAttackBehavior
extends Node

## Fire Imp ranged attack: spawns a fireball projectile at the player instead of melee.

var projectile_speed: float = 300.0
var projectile_damage: float = 10.0
var projectile_lifetime: float = 3.0

func _ready() -> void:
	# Tell the enemy to skip melee hitbox activation
	var enemy = get_parent()
	if enemy:
		enemy.use_ranged_attack = true

func do_ranged_attack(enemy: CharacterBody2D) -> void:
	if enemy.player == null or not is_instance_valid(enemy.player):
		return

	var direction: Vector2 = (enemy.player.global_position - enemy.global_position).normalized()
	_spawn_fireball(enemy, direction)

func _spawn_fireball(enemy: CharacterBody2D, direction: Vector2) -> void:
	var projectile := Area2D.new()
	projectile.global_position = enemy.global_position + direction * 20.0
	projectile.collision_layer = 0
	projectile.collision_mask = 0

	# Hitbox for the fireball
	var hitbox := Hitbox.new()
	hitbox.damage = projectile_damage
	hitbox.one_shot = true
	hitbox.collision_layer = 64  # Enemy projectile layer
	hitbox.collision_mask = 16   # Player hurtbox layer
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	hitbox.add_child(shape)
	projectile.add_child(hitbox)

	# Visual
	var sprite := Sprite2D.new()
	sprite.texture = PlaceholderSprites.create_circle_texture(8, Color(1.0, 0.5, 0.1, 0.9))
	projectile.add_child(sprite)

	# Glow core
	var core := Sprite2D.new()
	core.texture = PlaceholderSprites.create_circle_texture(4, Color(1.0, 0.9, 0.5, 0.7))
	projectile.add_child(core)

	# Trail
	var trail := Line2D.new()
	trail.width = 3.0
	trail.default_color = Color(1.0, 0.4, 0.1, 0.5)
	trail.add_point(Vector2.ZERO)
	trail.add_point(-direction * 12.0)
	projectile.add_child(trail)

	var parent := enemy.get_parent()
	if parent:
		parent.add_child(projectile)

	# Movement tween
	var target_pos: Vector2 = projectile.global_position + direction * projectile_speed * projectile_lifetime
	var tween := projectile.create_tween()
	tween.tween_property(projectile, "global_position", target_pos, projectile_lifetime)
	tween.tween_callback(projectile.queue_free)
