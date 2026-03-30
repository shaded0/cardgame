class_name CombatFeedback
extends RefCounted

## Centralizes combat feedback so gameplay nodes can focus on state changes.
## This also lets us prewarm the common first-hit assets up front.

static var _is_prewarmed: bool = false

static func prewarm_common_assets() -> void:
	if _is_prewarmed:
		return
	_is_prewarmed = true
	SpellEffectVisual.prewarm_common_effects()

static func show_enemy_hit(enemy: Node2D, parent: Node, anim_sprite: Node2D, pos: Vector2, damage: float) -> void:
	prewarm_common_assets()
	if parent != null and is_instance_valid(parent):
		DamageNumber.spawn(parent, pos, damage, Color(1.0, 1.0, 1.0))
		ScreenFX.spawn_hit_sparks(parent, pos, 4, Color(1.0, 0.8, 0.3))
	ScreenFX.shake(enemy, 4.0, 0.08)
	_play_scale_punch(anim_sprite, Vector2(1.15, 0.85), Vector2(0.95, 1.05))

static func show_player_hit(player: Node2D, parent: Node, anim_sprite: Node2D, pos: Vector2, damage: float) -> void:
	prewarm_common_assets()
	if parent != null and is_instance_valid(parent):
		DamageNumber.spawn(parent, pos, damage, Color(1.0, 0.3, 0.3))
		ScreenFX.spawn_hit_sparks(parent, pos, 5, Color(1.0, 0.4, 0.3))
	ScreenFX.shake(player, 6.0, 0.12)
	ScreenFX.flash(player, Color(1.0, 0.2, 0.1, 0.15), 0.08)
	_play_scale_punch(anim_sprite, Vector2(1.12, 0.88), Vector2(0.95, 1.05))

static func show_attack_connect(attacker: Node, tree: SceneTree, duration: float = 0.04) -> void:
	prewarm_common_assets()
	ScreenFX.shake(attacker, 3.0, 0.06)
	ScreenFX.hit_freeze(tree, duration)

static func _play_scale_punch(target: Node2D, first_scale: Vector2, second_scale: Vector2) -> void:
	if target == null or not is_instance_valid(target):
		return
	var punch_tween := target.create_tween()
	punch_tween.tween_property(target, "scale", first_scale, 0.04)
	punch_tween.tween_property(target, "scale", second_scale, 0.04)
	punch_tween.tween_property(target, "scale", Vector2.ONE, 0.04)
