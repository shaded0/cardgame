extends "res://tests/support/test_case.gd"

const Factory = preload("res://tests/support/test_factory.gd")
const PickupScript = preload("res://scripts/levels/pickup.gd")

func test_pickup_collect_applies_effect_only_once() -> void:
	var player := Factory.make_player_controller(root)
	var health: HealthComponent = player.get_node("HealthComponent")
	health.set_current_health(50.0)

	var pickup: Pickup = PickupScript.new()
	root.add_child(pickup)
	pickup.setup(Pickup.PickupType.HEALTH, Vector2.ZERO)

	pickup._collect(player)
	pickup._collect(player)

	assert_eq(health.current_health, 55.0, "Pickups should only heal once even if multiple collection paths fire before the node is freed.")
	assert_true(pickup.is_queued_for_deletion(), "Collected pickups should still clean themselves up.")
