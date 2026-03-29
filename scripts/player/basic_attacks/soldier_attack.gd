extends BaseAttack

## Melee arc attack — short range, high damage, with visible swing arc.

func execute(player: PlayerController, direction: Vector2) -> void:
	var hitbox: Hitbox = player.get_node_or_null("Hitbox") as Hitbox
	if hitbox == null:
		return
	var hitbox_shape: CollisionShape2D = hitbox.get_node_or_null("CollisionShape2D")
	if hitbox_shape == null:
		return

	hitbox.position = direction * 54.0
	hitbox_shape.disabled = false
	hitbox.damage = player.get_effective_damage() if player.has_method("get_effective_damage") else player.attack_damage

	_spawn_swing_arc(player, direction)

func _spawn_swing_arc(player: PlayerController, direction: Vector2) -> void:
	var parent: Node = player.get_parent()
	if parent == null or not is_instance_valid(parent):
		return

	var arc := Line2D.new()
	arc.z_index = 5
	arc.width = 2.0
	arc.default_color = Color(0.8, 0.85, 1.0, 0.7)

	var base_angle: float = direction.angle()
	var arc_spread: float = 1.2
	var arc_radius: float = 54.0
	var num_points: int = 8
	for i in range(num_points + 1):
		var t: float = float(i) / float(num_points)
		var angle: float = base_angle - arc_spread + t * arc_spread * 2.0
		arc.add_point(Vector2(cos(angle), sin(angle)) * arc_radius)

	player.add_child(arc)

	var tween: Tween = arc.create_tween()
	tween.tween_property(arc, "modulate:a", 0.0, 0.25)
	tween.tween_callback(arc.queue_free)

func end_attack(player: PlayerController) -> void:
	var hitbox: Hitbox = player.get_node_or_null("Hitbox") as Hitbox
	if hitbox == null:
		return
	var hitbox_shape: CollisionShape2D = hitbox.get_node_or_null("CollisionShape2D")
	if hitbox_shape == null:
		return
	hitbox_shape.disabled = true
	hitbox.position = Vector2.ZERO

func get_attack_duration() -> float:
	return 0.5
