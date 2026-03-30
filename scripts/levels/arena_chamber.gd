extends "res://scripts/levels/arena_base.gd"

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
	var variant: int = randi() % 5
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
		3:
			# Cross formation — 4 pillars forming +, creates natural sub-rooms
			_add_obstacle(Obstacle.ObstacleType.PILLAR, Vector2(0, -180))
			_add_obstacle(Obstacle.ObstacleType.PILLAR, Vector2(0, 180))
			_add_obstacle(Obstacle.ObstacleType.PILLAR, Vector2(-280, 0))
			_add_obstacle(Obstacle.ObstacleType.PILLAR, Vector2(280, 0))
			_add_obstacle(Obstacle.ObstacleType.WALL_V, Vector2(0, -80))
			_add_obstacle(Obstacle.ObstacleType.WALL_V, Vector2(0, 80))
			_add_obstacle(Obstacle.ObstacleType.CRATE, Vector2(-150, -75))
			_add_obstacle(Obstacle.ObstacleType.CRATE, Vector2(150, 75))
			_add_obstacle(Obstacle.ObstacleType.CRATE, Vector2(-150, 75))
		4:
			# Arena pit — wide ring of pillars with open center
			for i in range(8):
				var angle: float = float(i) / 8.0 * TAU
				var pos := Vector2(cos(angle) * 380.0, sin(angle) * 190.0)
				_add_obstacle(Obstacle.ObstacleType.PILLAR, pos)
			# Scattered crates inside the ring
			_add_obstacle(Obstacle.ObstacleType.CRATE, Vector2(-100, -40))
			_add_obstacle(Obstacle.ObstacleType.CRATE, Vector2(120, 50))
			_add_obstacle(Obstacle.ObstacleType.CRATE, Vector2(0, -90))

func _place_decorations() -> void:
	match floor_theme:
		FloorTheme.RITUAL:
			# Ritual chamber — altar centerpiece, skull piles, blood
			_add_decoration(ArenaDecoration.DecorType.ALTAR, Vector2(0, 0))
			_add_decoration(ArenaDecoration.DecorType.SKULL_PILE, Vector2(-220, -110))
			_add_decoration(ArenaDecoration.DecorType.SKULL_PILE, Vector2(220, -110))
			_add_decoration(ArenaDecoration.DecorType.SKULL_PILE, Vector2(-220, 110))
			_add_decoration(ArenaDecoration.DecorType.SKULL_PILE, Vector2(220, 110))
			_add_decoration(ArenaDecoration.DecorType.BLOOD_STAIN, Vector2(-60, 30))
			_add_decoration(ArenaDecoration.DecorType.BLOOD_STAIN, Vector2(80, -40))
			_add_decoration(ArenaDecoration.DecorType.BLOOD_STAIN, Vector2(20, 80))
			_spawn_perimeter_decorations(8, 4)
			_spawn_random_decorations(4)
		FloorTheme.MAGMA_CORRIDOR:
			# Magma chamber — braziers and lava pools
			_add_decoration(ArenaDecoration.DecorType.BRAZIER, Vector2(-500, 0))
			_add_decoration(ArenaDecoration.DecorType.BRAZIER, Vector2(500, 0))
			_add_decoration(ArenaDecoration.DecorType.LAVA_POOL, Vector2(-350, -120))
			_add_decoration(ArenaDecoration.DecorType.LAVA_POOL, Vector2(350, 120))
			_spawn_perimeter_decorations(6, 2)
			_spawn_random_decorations(4)
		_:
			# Antechamber / default — braziers with banner flanks
			_add_decoration(ArenaDecoration.DecorType.BRAZIER, Vector2(-500, 0))
			_add_decoration(ArenaDecoration.DecorType.BRAZIER, Vector2(500, 0))
			_add_decoration(ArenaDecoration.DecorType.BANNER, Vector2(-450, -80))
			_add_decoration(ArenaDecoration.DecorType.BANNER, Vector2(-450, 80))
			_add_decoration(ArenaDecoration.DecorType.BANNER, Vector2(450, -80))
			_add_decoration(ArenaDecoration.DecorType.BANNER, Vector2(450, 80))
			_spawn_perimeter_decorations(8, 4)
			_spawn_random_decorations(6)
