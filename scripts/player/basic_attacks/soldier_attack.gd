extends BaseAttack

## Melee arc attack — short range, high damage

func execute(player: CharacterBody2D, direction: Vector2) -> void:
	var hitbox: Area2D = player.get_node("Hitbox")
	var hitbox_shape: CollisionShape2D = hitbox.get_node("CollisionShape2D")

	# Position hitbox close to player in facing direction
	hitbox.position = direction * 18.0
	hitbox_shape.disabled = false
	hitbox.damage = player.attack_damage

func end_attack(player: CharacterBody2D) -> void:
	var hitbox: Area2D = player.get_node("Hitbox")
	var hitbox_shape: CollisionShape2D = hitbox.get_node("CollisionShape2D")
	hitbox_shape.disabled = true
	hitbox.position = Vector2.ZERO

func get_attack_duration() -> float:
	return 0.5
