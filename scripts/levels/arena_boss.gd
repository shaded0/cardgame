extends "res://scripts/levels/arena_base.gd"

## Large boss arena with corner pillars. Forces golem boss spawn.
## The Molten Throne — most dramatic visual treatment.

var golem_data: EnemyData = preload("res://resources/enemy_data/golem_boss_data.tres")

func _ready() -> void:
	arena_radius = 1300.0
	grid_count = 22
	floor_theme = FloorTheme.MOLTEN_THRONE
	_theme_set_by_subclass = true
	enemies_to_spawn = max(enemies_to_spawn, 1)
	super._ready()
	_place_obstacles()
	_place_decorations()
	_spawn_random_grass(12)

func _pick_enemy_data() -> EnemyData:
	return golem_data

func _place_obstacles() -> void:
	# Corner pillars (scaled up)
	_add_obstacle(Obstacle.ObstacleType.PILLAR, Vector2(-300, -150))
	_add_obstacle(Obstacle.ObstacleType.PILLAR, Vector2(300, -150))
	_add_obstacle(Obstacle.ObstacleType.PILLAR, Vector2(-300, 150))
	_add_obstacle(Obstacle.ObstacleType.PILLAR, Vector2(300, 150))

	# Small cover near center
	_add_obstacle(Obstacle.ObstacleType.CRATE, Vector2(-120, 0))
	_add_obstacle(Obstacle.ObstacleType.CRATE, Vector2(120, 0))

func _place_decorations() -> void:
	# 4 large braziers at corners (supplement pillars)
	_add_decoration(ArenaDecoration.DecorType.BRAZIER, Vector2(-400, -200))
	_add_decoration(ArenaDecoration.DecorType.BRAZIER, Vector2(400, -200))
	_add_decoration(ArenaDecoration.DecorType.BRAZIER, Vector2(-400, 200))
	_add_decoration(ArenaDecoration.DecorType.BRAZIER, Vector2(400, 200))
	# 2 lava pools near edges
	_add_decoration(ArenaDecoration.DecorType.LAVA_POOL, Vector2(-550, 0))
	_add_decoration(ArenaDecoration.DecorType.LAVA_POOL, Vector2(550, 0))
	# Heavy scatter of rubble and bones
	_spawn_random_decorations(10)
