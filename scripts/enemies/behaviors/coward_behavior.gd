class_name CowardBehavior
extends Node

## Mushroom Shaman flee behavior: runs from the player, moves toward nearest ally if far.

var flee_distance: float = 150.0
var flee_speed_mult: float = 1.2

func before_physics(enemy: CharacterBody2D, _delta: float) -> bool:
	if enemy.player == null or not is_instance_valid(enemy.player):
		return false

	if enemy.current_state == enemy.State.ATTACK or enemy.current_state == enemy.State.HURT:
		return false

	var dist: float = enemy.global_position.distance_to(enemy.player.global_position)
	if dist >= flee_distance:
		return false

	# Flee away from player
	var flee_dir: Vector2 = (enemy.global_position - enemy.player.global_position).normalized()

	# Bias toward nearest ally if available
	var nearest_ally := _find_nearest_ally(enemy)
	if nearest_ally != null:
		var ally_dir: Vector2 = (nearest_ally.global_position - enemy.global_position).normalized()
		flee_dir = (flee_dir + ally_dir * 0.5).normalized()

	enemy.velocity = flee_dir * enemy.move_speed * flee_speed_mult
	enemy.anim_sprite.rotation = flee_dir.angle() + PI / 2.0
	enemy.move_and_slide()
	enemy._play_anim(&"run")
	return true

func _find_nearest_ally(enemy: CharacterBody2D) -> CharacterBody2D:
	var nearest: CharacterBody2D = null
	var nearest_dist: float = INF

	for other in enemy.get_tree().get_nodes_in_group("enemies"):
		if other == enemy or not is_instance_valid(other):
			continue
		if other is CharacterBody2D and other.current_state != other.State.DEAD:
			var d: float = enemy.global_position.distance_to(other.global_position)
			if d < nearest_dist:
				nearest_dist = d
				nearest = other as CharacterBody2D

	return nearest
