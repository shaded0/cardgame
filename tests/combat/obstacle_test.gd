extends "res://tests/support/test_case.gd"

const Factory = preload("res://tests/support/test_factory.gd")
const ObstacleScript = preload("res://scripts/levels/obstacle.gd")
const HitboxScript = preload("res://scripts/combat/hitbox.gd")

func test_obstacle_projectile_blocker_does_not_delete_character_melee_hitbox() -> void:
	var player := Factory.make_player_controller(root)
	var obstacle: Obstacle = ObstacleScript.new()
	root.add_child(obstacle)
	obstacle.setup(Obstacle.ObstacleType.CRATE, Vector2.ZERO)

	obstacle._on_projectile_hit(player.hitbox)

	assert_false(player.hitbox.is_queued_for_deletion(), "Obstacle projectile blockers should not delete the player's persistent melee hitbox.")

func test_obstacle_projectile_blocker_still_deletes_projectile_hitboxes() -> void:
	var obstacle: Obstacle = ObstacleScript.new()
	root.add_child(obstacle)
	obstacle.setup(Obstacle.ObstacleType.CRATE, Vector2.ZERO)

	var projectile_owner := Node2D.new()
	root.add_child(projectile_owner)
	var projectile_hitbox: Hitbox = HitboxScript.new()
	projectile_owner.add_child(projectile_hitbox)

	obstacle._on_projectile_hit(projectile_hitbox)

	assert_true(projectile_hitbox.is_queued_for_deletion(), "Obstacle projectile blockers should still delete projectile hitboxes.")
