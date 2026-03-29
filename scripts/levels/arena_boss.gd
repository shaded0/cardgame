extends ArenaBase

## Large boss arena with corner pillars. Forces golem boss spawn.

var golem_data: EnemyData = preload("res://resources/enemy_data/golem_boss_data.tres")

func _ready() -> void:
	arena_radius = 900.0
	grid_count = 14
	enemies_to_spawn = max(enemies_to_spawn, 1)
	super._ready()
	_place_obstacles()

func _pick_enemy_data() -> EnemyData:
	return golem_data

func _place_obstacles() -> void:
	# Corner pillars
	_add_obstacle(Obstacle.ObstacleType.PILLAR, Vector2(-200, -100))
	_add_obstacle(Obstacle.ObstacleType.PILLAR, Vector2(200, -100))
	_add_obstacle(Obstacle.ObstacleType.PILLAR, Vector2(-200, 100))
	_add_obstacle(Obstacle.ObstacleType.PILLAR, Vector2(200, 100))

	# Small cover near center
	_add_obstacle(Obstacle.ObstacleType.CRATE, Vector2(-80, 0))
	_add_obstacle(Obstacle.ObstacleType.CRATE, Vector2(80, 0))
