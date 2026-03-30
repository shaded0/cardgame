extends "res://tests/support/test_case.gd"

const Factory = preload("res://tests/support/test_factory.gd")
const FakeEnemyOwnerScript = preload("res://tests/support/fake_enemy_owner.gd")
const ResurrectBehaviorScript = preload("res://scripts/enemies/behaviors/resurrect_behavior.gd")

func test_try_connect_death_only_queues_one_resurrection_per_enemy() -> void:
	var owner: CharacterBody2D = FakeEnemyOwnerScript.new()
	owner.name = "BoneColossus"
	owner.global_position = Vector2.ZERO
	owner.add_to_group("enemies")
	root.add_child(owner)

	var behavior: ResurrectBehavior = ResurrectBehaviorScript.new()
	behavior.resurrect_chance = 1.0
	behavior.resurrect_range = 9999.0
	owner.add_child(behavior)

	var other: CharacterBody2D = FakeEnemyOwnerScript.new()
	other.name = "Fallen"
	other.global_position = Vector2(40, 0)
	other.add_to_group("enemies")
	root.add_child(other)
	var health: HealthComponent = Factory.add_health(other, 20.0, 20.0)

	behavior._try_connect_death(other)
	behavior._try_connect_death(other)
	health.take_damage(50.0)

	assert_eq(behavior._pending_resurrections.size(), 1, "Connecting the same enemy twice should not queue duplicate resurrection entries when it dies.")

func test_resurrect_behavior_disconnects_tree_listener_on_exit() -> void:
	var owner: CharacterBody2D = FakeEnemyOwnerScript.new()
	owner.name = "BoneColossus"
	owner.add_to_group("enemies")
	root.add_child(owner)

	var behavior: ResurrectBehavior = ResurrectBehaviorScript.new()
	owner.add_child(behavior)
	await tree.process_frame

	var node_added_cb := Callable(behavior, "_on_node_added")
	assert_true(tree.node_added.is_connected(node_added_cb), "Resurrect behavior should subscribe to SceneTree.node_added while active.")

	behavior.queue_free()
	root.propagate_notification(Node.NOTIFICATION_EXIT_TREE)

	assert_false(tree.node_added.is_connected(node_added_cb), "Resurrect behavior should disconnect SceneTree.node_added when it leaves the tree.")
