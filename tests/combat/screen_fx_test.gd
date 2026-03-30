extends "res://tests/support/test_case.gd"

const ScreenFXScript = preload("res://scripts/combat/screen_fx.gd")

func after_each() -> void:
	Engine.time_scale = 1.0
	ScreenFXScript._hit_freeze_depth = 0
	ScreenFXScript._hit_freeze_restore_scale = 1.0

func test_hit_freeze_restores_previous_time_scale_after_completion() -> void:
	Engine.time_scale = 0.45

	await ScreenFXScript.hit_freeze(tree, 0.02)

	assert_near(Engine.time_scale, 0.45, 0.001, "ScreenFX hit freeze should restore the previous engine time scale instead of forcing normal speed and stomping tactical slowdown effects.")

func test_overlapping_hit_freeze_restores_original_time_scale() -> void:
	Engine.time_scale = 0.45

	ScreenFXScript.hit_freeze(tree, 0.03)
	await tree.create_timer(0.01, true, false, true).timeout
	ScreenFXScript.hit_freeze(tree, 0.03)
	await tree.create_timer(0.08, true, false, true).timeout

	assert_near(Engine.time_scale, 0.45, 0.001, "Overlapping ScreenFX hit freezes should unwind to the original time scale instead of leaving the game at normal speed or stuck in slowdown.")
