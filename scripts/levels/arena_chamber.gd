extends ArenaBase

## Open chamber with scattered pillars for cover.
## Three layout variants selected randomly for replay variety.

func _ready() -> void:
	# Use RITUAL theme for elite rooms
	if GameManager.current_room and GameManager.current_room.room_type == RoomData.RoomType.ELITE:
		floor_theme = FloorTheme.RITUAL
		_theme_set_by_subclass = true
	super._ready()
	_place_obstacles()
	_place_decorations()
	_spawn_random_grass(10)

func _place_obstacles() -> void:
	var variant: int = randi() % 3
	match variant:
		0:
			# Scattered pillars (original layout, scaled up)
			_add_obstacle(Obstacle.ObstacleType.PILLAR, Vector2(-210, -84))
			_add_obstacle(Obstacle.ObstacleType.PILLAR, Vector2(210, -84))
			_add_obstacle(Obstacle.ObstacleType.PILLAR, Vector2(-168, 112))
			_add_obstacle(Obstacle.ObstacleType.PILLAR, Vector2(168, 112))
			_add_obstacle(Obstacle.ObstacleType.PILLAR, Vector2(0, -168))
			_add_obstacle(Obstacle.ObstacleType.CRATE, Vector2(-350, 28))
			_add_obstacle(Obstacle.ObstacleType.CRATE, Vector2(350, 28))
		1:
			# Ring of 6 pillars around center
			for i in range(6):
				var angle: float = float(i) / 6.0 * TAU
				var pos := Vector2(cos(angle) * 280.0, sin(angle) * 140.0)
				_add_obstacle(Obstacle.ObstacleType.PILLAR, pos)
			_add_obstacle(Obstacle.ObstacleType.CRATE, Vector2(-380, -50))
			_add_obstacle(Obstacle.ObstacleType.CRATE, Vector2(380, 50))
		2:
			# L-shaped cluster — pillars grouped on one side, open space on the other
			_add_obstacle(Obstacle.ObstacleType.PILLAR, Vector2(-300, -120))
			_add_obstacle(Obstacle.ObstacleType.PILLAR, Vector2(-300, 0))
			_add_obstacle(Obstacle.ObstacleType.PILLAR, Vector2(-300, 120))
			_add_obstacle(Obstacle.ObstacleType.PILLAR, Vector2(-180, 120))
			_add_obstacle(Obstacle.ObstacleType.WALL_H, Vector2(-240, -180))
			_add_obstacle(Obstacle.ObstacleType.CRATE, Vector2(200, -60))
			_add_obstacle(Obstacle.ObstacleType.CRATE, Vector2(250, 60))

func _place_decorations() -> void:
	# 4 braziers at cardinal edges for atmosphere
	_add_decoration(ArenaDecoration.DecorType.BRAZIER, Vector2(-500, 0))
	_add_decoration(ArenaDecoration.DecorType.BRAZIER, Vector2(500, 0))
	_add_decoration(ArenaDecoration.DecorType.BRAZIER, Vector2(0, -250))
	_add_decoration(ArenaDecoration.DecorType.BRAZIER, Vector2(0, 250))
	# Random scatter of rubble/bones
	_spawn_random_decorations(6)
