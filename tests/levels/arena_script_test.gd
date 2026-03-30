extends "res://tests/support/test_case.gd"

const ARENA_SCRIPT_PATHS: Array[String] = [
	"res://scripts/levels/arena_base.gd",
	"res://scripts/levels/arena_chamber.gd",
	"res://scripts/levels/arena_halls.gd",
	"res://scripts/levels/arena_boss.gd",
	"res://scripts/levels/test_arena.gd",
]

func test_arena_scripts_load_cleanly() -> void:
	for script_path in ARENA_SCRIPT_PATHS:
		var script := load(script_path)
		assert_not_null(script, "Arena script should load without parse errors: %s" % script_path)
