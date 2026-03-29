extends ProgressBar

## Simple style setup for the health bar.
## Keeping UI styling in script means these bars look consistent across scenes.
func _ready() -> void:
	# Fill stays red; background is darker to improve contrast.
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.85, 0.15, 0.15, 1.0)
	style.corner_radius_top_right = 1
	style.corner_radius_bottom_right = 1
	add_theme_stylebox_override("fill", style)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.05, 0.05, 0.8)
	bg_style.corner_radius_top_right = 1
	bg_style.corner_radius_bottom_right = 1
	add_theme_stylebox_override("background", bg_style)
