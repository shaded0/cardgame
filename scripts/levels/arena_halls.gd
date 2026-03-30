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
	var variant: int = randi() % 3
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
		2:
			# Pillared gallery — dense colonnade
			for i in range(-4, 5):
				_add_obstacle(Obstacle.ObstacleType.PILLAR, Vector2(-130, i * 80.0))
				_add_obstacle(Obstacle.ObstacleType.PILLAR, Vector2(130, i * 80.0))
			_add_obstacle(Obstacle.ObstacleType.WALL_H, Vector2(0, -380))
			_add_obstacle(Obstacle.ObstacleType.WALL_H, Vector2(0, 380))
			# Crates tucked between pillars
			_add_obstacle(Obstacle.ObstacleType.CRATE, Vector2(0, -200))
			_add_obstacle(Obstacle.ObstacleType.CRATE, Vector2(0, 200))

func _place_decorations() -> void:
	# Braziers at corridor ends
	_add_decoration(ArenaDecoration.DecorType.BRAZIER, Vector2(0, -350))
	_add_decoration(ArenaDecoration.DecorType.BRAZIER, Vector2(0, 350))
	# Banners flanking corridor ends
	_add_decoration(ArenaDecoration.DecorType.BANNER, Vector2(-80, -340))
	_add_decoration(ArenaDecoration.DecorType.BANNER, Vector2(80, -340))
	_add_decoration(ArenaDecoration.DecorType.BANNER, Vector2(-80, 340))
	_add_decoration(ArenaDecoration.DecorType.BANNER, Vector2(80, 340))
	# Torches along corridor walls
	for i in range(-3, 4):
		var y_pos: float = float(i) * 100.0
		_add_decoration(ArenaDecoration.DecorType.TORCH_WALL, Vector2(-240.0, y_pos))
		_add_decoration(ArenaDecoration.DecorType.TORCH_WALL, Vector2(240.0, y_pos))
	# Chains along pillar columns
	for i in range(6):
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var y_pos: float = float(i - 2) * 110.0
		_add_decoration(ArenaDecoration.DecorType.CHAIN, Vector2(side * 220.0, y_pos))
	# Lava pools for magma theme
	if floor_theme == FloorTheme.MAGMA_CORRIDOR:
		_add_decoration(ArenaDecoration.DecorType.LAVA_POOL, Vector2(-300, -180))
		_add_decoration(ArenaDecoration.DecorType.LAVA_POOL, Vector2(300, 180))
	# Scatter
	_spawn_random_decorations(4)
