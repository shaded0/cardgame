extends "res://tests/support/test_case.gd"

const HitboxScript = preload("res://scripts/combat/hitbox.gd")
const HurtboxScript = preload("res://scripts/combat/hurtbox.gd")

func after_each() -> void:
	Engine.time_scale = 1.0

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

func test_hit_stop_restores_previous_time_scale_after_completion() -> void:
	var hitbox = HitboxScript.new()
	root.add_child(hitbox)
	await tree.process_frame

	Engine.time_scale = 0.45
	await hitbox._do_hit_stop()

	assert_near(Engine.time_scale, 0.45, 0.001, "Hitstop should restore the previous engine time scale instead of forcing normal speed and stomping other slowdown effects.")

func test_overlapping_hit_stop_restores_original_time_scale() -> void:
	var hitbox = HitboxScript.new()
	root.add_child(hitbox)
	await tree.process_frame

	Engine.time_scale = 0.45
	hitbox._do_hit_stop()
	await tree.create_timer(0.01, true, false, true).timeout
	hitbox._do_hit_stop()
	await tree.create_timer(0.08, true, false, true).timeout

	assert_near(Engine.time_scale, 0.45, 0.001, "Overlapping hitstops should unwind back to the original time scale instead of leaving the game stuck in slow motion.")
