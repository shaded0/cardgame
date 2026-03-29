extends ArenaBase

## Long hallway with pillar rows forming corridors.

func _ready() -> void:
	super._ready()
	_place_obstacles()

func _place_obstacles() -> void:
	# Two rows of pillars forming a corridor
	for i in range(-2, 3):
		_add_obstacle(0, Vector2(-100, i * 100.0))  # Left pillar row
		_add_obstacle(0, Vector2(100, i * 100.0))   # Right pillar row

	# Horizontal walls at ends
	_add_obstacle(1, Vector2(0, -280))   # WALL_H top
	_add_obstacle(1, Vector2(0, 280))    # WALL_H bottom
