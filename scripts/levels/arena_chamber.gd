extends ArenaBase

## Open chamber with scattered pillars for cover.

func _ready() -> void:
	super._ready()
	_place_obstacles()

func _place_obstacles() -> void:
	# Scattered pillars
	_add_obstacle(0, Vector2(-150, -60))   # PILLAR
	_add_obstacle(0, Vector2(150, -60))
	_add_obstacle(0, Vector2(-120, 80))
	_add_obstacle(0, Vector2(120, 80))
	_add_obstacle(0, Vector2(0, -120))
	# A few crates for variety
	_add_obstacle(3, Vector2(-250, 20))    # CRATE
	_add_obstacle(3, Vector2(250, 20))
