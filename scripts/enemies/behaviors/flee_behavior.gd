class_name FleeBehavior
extends Node

## Fire Imp flee behavior: runs away when the player gets too close.

var flee_distance: float = 100.0
var flee_speed_mult: float = 1.5

func before_physics(enemy: CharacterBody2D, _delta: float) -> bool:
	if enemy.player == null or not is_instance_valid(enemy.player):
		return false

	# Only flee when not attacking or hurt
	if enemy.current_state == enemy.State.ATTACK or enemy.current_state == enemy.State.HURT:
		return false

	var dist: float = enemy.global_position.distance_to(enemy.player.global_position)
	if dist >= flee_distance:
		return false

	# Flee away from player
	var flee_dir: Vector2 = (enemy.global_position - enemy.player.global_position).normalized()
	enemy.velocity = flee_dir * enemy.move_speed * flee_speed_mult
	enemy.anim_sprite.rotation = flee_dir.angle() + PI / 2.0
	enemy.move_and_slide()
	enemy._play_anim(&"run")
	return true
