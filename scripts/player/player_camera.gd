class_name PlayerCamera
extends Camera2D

## Camera that leads slightly toward the mouse cursor for better spatial awareness.
## Attach as a child of the player — position_smoothing handles the interpolation.

## How far the camera can lead ahead of the player (in pixels).
@export var lead_distance: float = 80.0
## How quickly the camera catches up to the lead target (higher = snappier).
@export var lead_speed: float = 4.0

func _ready() -> void:
	zoom = Vector2(0.85, 0.85)
	position_smoothing_enabled = true
	position_smoothing_speed = 8.0

func _process(delta: float) -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var player_pos: Vector2 = get_parent().global_position
	var to_mouse: Vector2 = (mouse_pos - player_pos)

	# Clamp the lead so the camera doesn't fly off-screen at large mouse distances
	var lead_target: Vector2 = to_mouse.limit_length(lead_distance)

	# Use position (not offset) so ScreenFX.shake can use offset independently
	position = position.lerp(lead_target, lead_speed * delta)
