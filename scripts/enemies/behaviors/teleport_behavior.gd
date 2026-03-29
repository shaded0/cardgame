class_name TeleportBehavior
extends Node

## Shadow Wraith teleport: randomly teleports near the player during chase.

var teleport_chance_per_sec: float = 0.2
var teleport_min_dist: float = 80.0
var teleport_max_dist: float = 120.0
var teleport_cooldown: float = 3.0

var _cooldown_timer: float = 1.5  # Initial delay before first teleport

func _process(delta: float) -> void:
	var enemy = get_parent()
	if enemy == null or not is_instance_valid(enemy):
		return
	if enemy.current_state != enemy.State.CHASE:
		return
	if enemy.player == null or not is_instance_valid(enemy.player):
		return

	_cooldown_timer -= delta
	if _cooldown_timer > 0.0:
		return

	# Roll for teleport
	if randf() < teleport_chance_per_sec * delta:
		_do_teleport(enemy)
		_cooldown_timer = teleport_cooldown

func _do_teleport(enemy: CharacterBody2D) -> void:
	# Fade out
	var tween := enemy.create_tween()
	tween.tween_property(enemy, "modulate:a", 0.1, 0.15)
	tween.tween_callback(func() -> void:
		if not is_instance_valid(enemy) or enemy.player == null or not is_instance_valid(enemy.player):
			return

		# Reposition near player
		var angle := randf() * TAU
		var dist := randf_range(teleport_min_dist, teleport_max_dist)
		var new_pos: Vector2 = enemy.player.global_position + Vector2(cos(angle), sin(angle)) * dist
		enemy.global_position = new_pos

		# Spawn VFX at new position
		SpellEffectVisual.spawn_burst(enemy.get_parent(), new_pos, 12.0, Color(0.5, 0.1, 0.8, 0.4), 0.25)
	)
	# Fade back in (wraith is normally 0.7 alpha)
	tween.tween_property(enemy, "modulate:a", 0.7, 0.2)
