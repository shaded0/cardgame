extends ProgressBar

## Stylized mana bar with animated arcane glow, shimmer,
## smooth value interpolation, full-mana glow pulse, icon, and value label.

var _flash_tween: Tween = null
var _interp_tween: Tween = null
var _full_mana_tween: Tween = null
var _is_full_mana: bool = false
var _prev_value: float = -1.0
var _value_label: Label = null
var _icon: Sprite2D = null

func _ready() -> void:
	# Mana fill with shader animation
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.4, 0.9, 1.0)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
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

	# Dark blue background with inner shadow
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.02, 0.02, 0.10, 0.95)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.border_color = Color(0.15, 0.2, 0.5, 0.5)
	bg_style.set_border_width_all(1)
	bg_style.shadow_color = Color(0.0, 0.0, 0.0, 0.3)
	bg_style.shadow_size = 2
	add_theme_stylebox_override("background", bg_style)

	_create_value_label()
	_create_icon()

func set_mana(current: float, maximum: float) -> void:
	max_value = maximum
	if _prev_value >= 0.0 and current > _prev_value:
		_flash_gain()
	_prev_value = current
	_check_full_mana(current)
	_update_value_label(current, maximum)

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
	_icon.texture = _make_crystal_texture()
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Position to the left of the bar
	_icon.position = Vector2(-12, size.y * 0.5)
	_icon.z_index = 1
	add_child(_icon)

static func _make_crystal_texture() -> ImageTexture:
	var w: int = 10
	var h: int = 14
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	# Diamond/crystal shape
	var cx: float = w / 2.0
	var cy: float = h / 2.0
	var main_color := Color(0.15, 0.35, 0.9, 1.0)
	var highlight := Color(0.5, 0.7, 1.0, 1.0)
	var dark := Color(0.08, 0.15, 0.55, 1.0)

	for x in range(w):
		for y in range(h):
			var dx: float = absf(float(x) - cx)
			var dy: float = absf(float(y) - cy)
			# Diamond shape: dx/half_w + dy/half_h <= 1
			var half_w: float = 4.5
			var half_h: float = 6.5
			if dx / half_w + dy / half_h <= 1.0:
				# Left-top facet highlight
				if float(x) < cx and float(y) < cy:
					img.set_pixel(x, y, highlight)
				# Right-bottom facet dark
				elif float(x) >= cx and float(y) >= cy:
					img.set_pixel(x, y, dark)
				else:
					img.set_pixel(x, y, main_color)

	return ImageTexture.create_from_image(img)
