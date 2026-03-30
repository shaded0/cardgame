extends ProgressBar

## Stylized health bar with animated molten gradient, damage flash,
## smooth value interpolation, low-health warning pulse, icon, and value label.

var _flash_tween: Tween = null
var _interp_tween: Tween = null
var _ghost_tween: Tween = null
var _low_health_tween: Tween = null
var _is_low_health: bool = false
var _prev_value: float = -1.0
var _ghost_bar: ProgressBar = null
var _value_label: Label = null
var _icon: Sprite2D = null

func _ready() -> void:
	# Main fill - red gradient with inner glow via shader
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.85, 0.15, 0.15, 1.0)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
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

	# Dark background with subtle red tint and inner shadow
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.12, 0.02, 0.02, 0.95)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.border_color = Color(0.6, 0.15, 0.1, 0.5)
	bg_style.set_border_width_all(1)
	bg_style.shadow_color = Color(0.0, 0.0, 0.0, 0.3)
	bg_style.shadow_size = 2
	add_theme_stylebox_override("background", bg_style)

	# Ghost bar — shows previous health, trails behind actual value
	_ghost_bar = ProgressBar.new()
	_ghost_bar.show_percentage = false
	_ghost_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ghost_bar.max_value = max_value
	_ghost_bar.value = max_value
	var ghost_fill := StyleBoxFlat.new()
	ghost_fill.bg_color = Color(1.0, 0.85, 0.7, 0.35)
	ghost_fill.corner_radius_top_left = 4
	ghost_fill.corner_radius_top_right = 4
	ghost_fill.corner_radius_bottom_right = 4
	ghost_fill.corner_radius_bottom_left = 4
	_ghost_bar.add_theme_stylebox_override("fill", ghost_fill)
	var ghost_bg := StyleBoxEmpty.new()
	_ghost_bar.add_theme_stylebox_override("background", ghost_bg)
	# Insert behind main fill
	add_child(_ghost_bar)
	move_child(_ghost_bar, 0)

	_create_value_label()
	_create_icon()

func set_health(current: float, maximum: float) -> void:
	max_value = maximum
	if _ghost_bar:
		_ghost_bar.max_value = maximum
	if _prev_value > 0.0 and current < _prev_value:
		_flash_damage()
		# Ghost bar trails behind — delay then catch up slowly
		if _ghost_bar:
			if _ghost_tween and _ghost_tween.is_valid():
				_ghost_tween.kill()
			_ghost_tween = create_tween()
			_ghost_tween.tween_interval(0.4)
			_ghost_tween.tween_property(_ghost_bar, "value", current, 0.6).set_ease(Tween.EASE_IN_OUT)
	elif _ghost_bar:
		# Healing — ghost follows immediately
		_ghost_bar.value = current
	_prev_value = current
	_check_low_health(current)
	_update_value_label(current, maximum)

	if _interp_tween and _interp_tween.is_valid():
		_interp_tween.kill()
	_interp_tween = create_tween()
	_interp_tween.tween_property(self, "value", current, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

func _check_low_health(current: float) -> void:
	var threshold := max_value * 0.25
	if current <= threshold and current > 0.0:
		if not _is_low_health:
			_is_low_health = true
			_start_low_health_pulse()
	else:
		if _is_low_health:
			_is_low_health = false
			_stop_low_health_pulse()

func _start_low_health_pulse() -> void:
	if _low_health_tween and _low_health_tween.is_valid():
		_low_health_tween.kill()
	_low_health_tween = create_tween().set_loops()
	_low_health_tween.tween_property(self, "modulate", Color(1.4, 0.6, 0.6, 1.0), 0.4).set_ease(Tween.EASE_IN_OUT)
	_low_health_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.4).set_ease(Tween.EASE_IN_OUT)

func _stop_low_health_pulse() -> void:
	if _low_health_tween and _low_health_tween.is_valid():
		_low_health_tween.kill()
		_low_health_tween = null
	modulate = Color(1, 1, 1, 1)

func _flash_damage() -> void:
	# Kill pulse during flash to avoid modulate conflicts
	if _low_health_tween and _low_health_tween.is_valid():
		_low_health_tween.kill()

	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	modulate = Color(2.0, 0.5, 0.5, 1.0)
	_flash_tween = create_tween()
	_flash_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.3)
	_flash_tween.finished.connect(func():
		if _is_low_health:
			_start_low_health_pulse()
	, CONNECT_ONE_SHOT)

func _create_value_label() -> void:
	_value_label = Label.new()
	_value_label.text = "%d / %d" % [int(value), int(max_value)]
	_value_label.add_theme_font_size_override("font_size", 13)
	_value_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
	_value_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.7))
	_value_label.add_theme_constant_override("shadow_offset_x", 1)
	_value_label.add_theme_constant_override("shadow_offset_y", 1)
	_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_value_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_value_label.offset_right = -6.0
	_value_label.offset_left = 6.0
	_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_value_label)

func _update_value_label(current: float, maximum: float) -> void:
	if _value_label:
		_value_label.text = "%d / %d" % [int(current), int(maximum)]

func _create_icon() -> void:
	_icon = Sprite2D.new()
	_icon.texture = _make_heart_texture()
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Position to the left of the bar
	_icon.position = Vector2(-12, size.y * 0.5)
	_icon.z_index = 1
	add_child(_icon)

static func _make_heart_texture() -> ImageTexture:
	var w: int = 12
	var h: int = 11
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	# Pixel art heart shape
	var heart := [
		"  ##  ##  ",
		" ########",
		" ########",
		" ########",
		"  ######  ",
		"  ######  ",
		"   ####   ",
		"   ####   ",
		"    ##    ",
		"    ##    ",
		"          ",
	]
	var main_color := Color(0.9, 0.15, 0.1, 1.0)
	var highlight := Color(1.0, 0.45, 0.35, 1.0)
	for y in range(mini(h, heart.size())):
		var row: String = heart[y]
		for x in range(mini(w, row.length())):
			if row[x] == "#":
				# Top-left highlight for dimension
				if y < 3 and x < 6:
					img.set_pixel(x, y, highlight)
				else:
					img.set_pixel(x, y, main_color)
	return ImageTexture.create_from_image(img)
