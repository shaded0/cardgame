extends "res://scripts/levels/arena_base.gd"

## Long hallway with pillar rows forming corridors.
## Two layout variants for replay variety.

func _ready() -> void:
	floor_theme = FloorTheme.MAGMA_CORRIDOR
	_theme_set_by_subclass = true
	super._ready()
	_place_obstacles()
	_place_decorations()
	_spawn_random_grass(6)

func _place_obstacles() -> void:
	var variant: int = randi() % 2
	match variant:
		0:
			# Straight corridor (scaled up)
			for i in range(-3, 4):
				_add_obstacle(Obstacle.ObstacleType.PILLAR, Vector2(-160, i * 110.0))
				_add_obstacle(Obstacle.ObstacleType.PILLAR, Vector2(160, i * 110.0))
			_add_obstacle(Obstacle.ObstacleType.WALL_H, Vector2(0, -400))
			_add_obstacle(Obstacle.ObstacleType.WALL_H, Vector2(0, 400))
		1:
			# Zigzag corridor — alternating wall segments create S-curve
			_add_obstacle(Obstacle.ObstacleType.WALL_H, Vector2(-120, -300))
			_add_obstacle(Obstacle.ObstacleType.PILLAR, Vector2(-200, -300))
			_add_obstacle(Obstacle.ObstacleType.WALL_H, Vector2(120, -100))
			_add_obstacle(Obstacle.ObstacleType.PILLAR, Vector2(200, -100))
			_add_obstacle(Obstacle.ObstacleType.WALL_H, Vector2(-120, 100))
			_add_obstacle(Obstacle.ObstacleType.PILLAR, Vector2(-200, 100))
			_add_obstacle(Obstacle.ObstacleType.WALL_H, Vector2(120, 300))
			_add_obstacle(Obstacle.ObstacleType.PILLAR, Vector2(200, 300))
			# End walls
			_add_obstacle(Obstacle.ObstacleType.WALL_H, Vector2(0, -430))
			_add_obstacle(Obstacle.ObstacleType.WALL_H, Vector2(0, 430))

func _place_decorations() -> void:
	# Braziers at corridor ends
	_add_decoration(ArenaDecoration.DecorType.BRAZIER, Vector2(0, -350))
	_add_decoration(ArenaDecoration.DecorType.BRAZIER, Vector2(0, 350))
	# Chains along pillar columns
	for i in range(4):
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var y_pos: float = float(i - 1) * 130.0
		_add_decoration(ArenaDecoration.DecorType.CHAIN, Vector2(side * 240.0, y_pos))
	# Rubble scatter
	_spawn_random_decorations(4)
