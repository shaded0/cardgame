extends ProgressBar

## Simple style setup for a mana bar.
## Using an override in code keeps a readable, reusable look even without editor theme assets.
func _ready() -> void:
	# Make the fill bright blue and keep a dark transparent background.
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.4, 0.9, 1.0)
	style.corner_radius_top_right = 1
	style.corner_radius_bottom_right = 1
	add_theme_stylebox_override("fill", style)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.05, 0.05, 0.15, 0.8)
	bg_style.corner_radius_top_right = 1
	bg_style.corner_radius_bottom_right = 1
	add_theme_stylebox_override("background", bg_style)
