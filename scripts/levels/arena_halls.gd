extends ArenaBase

## Long hallway with pillar rows forming corridors.

func _ready() -> void:
	super._ready()
	_place_obstacles()

func _place_obstacles() -> void:
	# Two rows of pillars forming a corridor
	for i in range(-2, 3):
		_add_obstacle(Obstacle.ObstacleType.PILLAR, Vector2(-100, i * 100.0))
		_add_obstacle(Obstacle.ObstacleType.PILLAR, Vector2(100, i * 100.0))

	# Horizontal walls at ends
	_add_obstacle(Obstacle.ObstacleType.WALL_H, Vector2(0, -280))
	_add_obstacle(Obstacle.ObstacleType.WALL_H, Vector2(0, 280))
