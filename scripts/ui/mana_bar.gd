extends ProgressBar

## Stylized mana bar with animated arcane glow and shimmer.

var _flash_tween: Tween = null

func _ready() -> void:
	# Mana fill with shader animation
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.4, 0.9, 1.0)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_right = 3
	style.corner_radius_bottom_left = 3
	add_theme_stylebox_override("fill", style)

	# Apply animated shader with blue/arcane colors
	var shader := load("res://shaders/health_bar_fire.gdshader") as Shader
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("color_left", Color(0.1, 0.25, 0.85, 1.0))
		mat.set_shader_parameter("color_right", Color(0.3, 0.5, 1.0, 1.0))
		mat.set_shader_parameter("shimmer_speed", 2.0)
		mat.set_shader_parameter("shimmer_intensity", 0.18)
		style.bg_color = Color(1.0, 1.0, 1.0, 1.0)
		material = mat

	# Dark blue background
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.03, 0.03, 0.12, 0.9)
	bg_style.corner_radius_top_left = 3
	bg_style.corner_radius_top_right = 3
	bg_style.corner_radius_bottom_right = 3
	bg_style.corner_radius_bottom_left = 3
	bg_style.border_color = Color(0.1, 0.15, 0.4, 0.4)
	bg_style.set_border_width_all(1)
	add_theme_stylebox_override("background", bg_style)

	value_changed.connect(_on_value_changed)

var _prev_value: float = -1.0

func _on_value_changed(new_value: float) -> void:
	if _prev_value >= 0.0 and new_value > _prev_value:
		_flash_gain()
	_prev_value = new_value

func _flash_gain() -> void:
	# Blue glow flash when gaining mana
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	modulate = Color(0.7, 0.8, 2.0, 1.0)
	_flash_tween = create_tween()
	_flash_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.25)
