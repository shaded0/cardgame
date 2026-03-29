extends ProgressBar

## Stylized mana bar with animated arcane glow, shimmer,
## smooth value interpolation, and full-mana glow pulse.

var _flash_tween: Tween = null
var _interp_tween: Tween = null
var _full_mana_tween: Tween = null
var _is_full_mana: bool = false
var _prev_value: float = -1.0

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

func set_mana(current: float, maximum: float) -> void:
	max_value = maximum
	if _prev_value >= 0.0 and current > _prev_value:
		_flash_gain()
	_prev_value = current
	_check_full_mana(current)

	if _interp_tween and _interp_tween.is_valid():
		_interp_tween.kill()
	_interp_tween = create_tween()
	_interp_tween.tween_property(self, "value", current, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

func _check_full_mana(current: float) -> void:
	if current >= max_value and max_value > 0.0:
		if not _is_full_mana:
			_is_full_mana = true
			_start_full_mana_glow()
	else:
		if _is_full_mana:
			_is_full_mana = false
			_stop_full_mana_glow()

func _start_full_mana_glow() -> void:
	if _full_mana_tween and _full_mana_tween.is_valid():
		_full_mana_tween.kill()
	_full_mana_tween = create_tween().set_loops()
	_full_mana_tween.tween_property(self, "modulate", Color(0.8, 0.9, 1.5, 1.0), 0.5).set_ease(Tween.EASE_IN_OUT)
	_full_mana_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5).set_ease(Tween.EASE_IN_OUT)

func _stop_full_mana_glow() -> void:
	if _full_mana_tween and _full_mana_tween.is_valid():
		_full_mana_tween.kill()
		_full_mana_tween = null
	modulate = Color(1, 1, 1, 1)

func _flash_gain() -> void:
	# Kill glow during flash to avoid modulate conflicts
	if _full_mana_tween and _full_mana_tween.is_valid():
		_full_mana_tween.kill()

	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	modulate = Color(0.7, 0.8, 2.0, 1.0)
	_flash_tween = create_tween()
	_flash_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.25)
	_flash_tween.finished.connect(func():
		if _is_full_mana:
			_start_full_mana_glow()
	, CONNECT_ONE_SHOT)
