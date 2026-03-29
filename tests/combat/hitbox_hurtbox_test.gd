extends "res://tests/support/test_case.gd"

const HitboxScript = preload("res://scripts/combat/hitbox.gd")
const HurtboxScript = preload("res://scripts/combat/hurtbox.gd")

func test_hitbox_notifies_hurtbox_when_overlap_occurs() -> void:
	var hitbox = HitboxScript.new()
	var hurtbox = HurtboxScript.new()

	var landed_count := 0
	var received_count := 0
	hitbox.hit_landed.connect(func(_hurtbox: Area2D) -> void:
		landed_count += 1
	)
	hurtbox.received_hit.connect(func(_hitbox: Hitbox) -> void:
		received_count += 1
	)

	hitbox._on_area_entered(hurtbox)

	assert_eq(landed_count, 1, "Hitbox should emit hit_landed when it touches a hurtbox.")
	assert_eq(received_count, 1, "Hurtbox should emit received_hit when it is not invincible.")

func test_invincible_hurtbox_suppresses_received_hit_signal() -> void:
	var hitbox = HitboxScript.new()
	var hurtbox = HurtboxScript.new()
	hurtbox.is_invincible = true

	var received_count := 0
	hurtbox.received_hit.connect(func(_hitbox: Hitbox) -> void:
		received_count += 1
	)

	hitbox._on_area_entered(hurtbox)

	assert_eq(received_count, 0, "Invincible hurtboxes should ignore incoming hits.")
