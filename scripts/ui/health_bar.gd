extends ProgressBar

## Stylized health bar with animated molten gradient and damage flash.

var _flash_tween: Tween = null

func _ready() -> void:
	# Main fill - red gradient with inner glow via shader
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.85, 0.15, 0.15, 1.0)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_right = 3
	style.corner_radius_bottom_left = 3
	add_theme_stylebox_override("fill", style)

	# Apply animated shader to the fill
	var shader := load("res://shaders/health_bar_fire.gdshader") as Shader
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("color_left", Color(0.9, 0.1, 0.05, 1.0))
		mat.set_shader_parameter("color_right", Color(1.0, 0.3, 0.1, 1.0))
		mat.set_shader_parameter("shimmer_speed", 1.5)
		mat.set_shader_parameter("shimmer_intensity", 0.12)
		style.bg_color = Color(1.0, 1.0, 1.0, 1.0)  # White base so shader colors show
		material = mat

	# Dark background with subtle red tint
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.03, 0.03, 0.9)
	bg_style.corner_radius_top_left = 3
	bg_style.corner_radius_top_right = 3
	bg_style.corner_radius_bottom_right = 3
	bg_style.corner_radius_bottom_left = 3
	bg_style.border_color = Color(0.5, 0.1, 0.1, 0.4)
	bg_style.set_border_width_all(1)
	add_theme_stylebox_override("background", bg_style)

	# Connect to value changes for damage flash
	value_changed.connect(_on_value_changed)

var _prev_value: float = -1.0

func _on_value_changed(new_value: float) -> void:
	if _prev_value > 0.0 and new_value < _prev_value:
		_flash_damage()
	_prev_value = new_value

func _flash_damage() -> void:
	# Quick red flash when taking damage
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	modulate = Color(2.0, 0.5, 0.5, 1.0)
	_flash_tween = create_tween()
	_flash_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.3)
