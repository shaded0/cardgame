extends ArenaBase

## Large boss arena with corner pillars.

func _ready() -> void:
	arena_radius = 600.0
	grid_count = 9
	enemies_to_spawn = max(enemies_to_spawn, 1)
	super._ready()
	_place_obstacles()

func _place_obstacles() -> void:
	# Corner pillars
	_add_obstacle(0, Vector2(-200, -100))
	_add_obstacle(0, Vector2(200, -100))
	_add_obstacle(0, Vector2(-200, 100))
	_add_obstacle(0, Vector2(200, 100))

	# Small cover near center
	_add_obstacle(3, Vector2(-80, 0))
	_add_obstacle(3, Vector2(80, 0))
