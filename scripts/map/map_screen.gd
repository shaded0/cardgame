extends Control

## Hades/Slay-the-Spire style overworld map.
## Draws room nodes vertically with connecting lines.
## Clicking an available room enters combat.

const TIER_SPACING: float = 160.0
const NODE_RADIUS: float = 28.0

var room_buttons: Dictionary = {}  # room_id -> Button
var room_button_pulses: Dictionary = {}  # room_id -> Tween
var _room_selection_locked: bool = false
var _active_rest_screen: RestScreen = null

func _ready() -> void:
	if not GameManager.run_active:
		GameManager.start_new_run()

	_build_map()
	var room_completed_cb := Callable(self, "_on_room_completed")
	if not GameManager.room_completed.is_connected(room_completed_cb):
		GameManager.room_completed.connect(room_completed_cb)

func _exit_tree() -> void:
	var room_completed_cb := Callable(self, "_on_room_completed")
	if GameManager.room_completed.is_connected(room_completed_cb):
		GameManager.room_completed.disconnect(room_completed_cb)

func _build_map() -> void:
	_clear_room_button_pulses()

	# Clear existing
	for child in get_children():
		if child.name != "Background" and child.name != "Title":
			child.queue_free()
	room_buttons.clear()

	# Background — animated fire shader at low intensity
	if not has_node("Background"):
		var bg := ColorRect.new()
		bg.name = "Background"
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		var fire_shader: Shader = load("res://shaders/fire_bg.gdshader")
		var mat := ShaderMaterial.new()
		mat.shader = fire_shader
		mat.set_shader_parameter("speed", 0.4)
		mat.set_shader_parameter("intensity", 0.25)
		mat.set_shader_parameter("base_color", Color(0.04, 0.04, 0.07, 1.0))
		mat.set_shader_parameter("fire_color_cool", Color(0.10, 0.02, 0.0, 1.0))
		mat.set_shader_parameter("fire_color_mid", Color(0.5, 0.12, 0.03, 1.0))
		mat.set_shader_parameter("fire_color_hot", Color(0.8, 0.4, 0.08, 1.0))
		bg.material = mat
		bg.color = Color.WHITE  # needed for shader to render
		add_child(bg)
		move_child(bg, 0)

	# Title
	if not has_node("Title"):
		var title := Label.new()
		title.name = "Title"
		title.text = "THE EMBER SANCTUM"
		title.add_theme_font_size_override("font_size", 36)
		title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4, 1.0))
		title.add_theme_color_override("font_outline_color", Color(0.5, 0.15, 0.0, 0.8))
		title.add_theme_constant_override("outline_size", 3)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.set_anchors_preset(Control.PRESET_CENTER_TOP)
		title.position = Vector2(-150, 20)
		title.size = Vector2(300, 40)
		add_child(title)

	# Lines container (drawn behind buttons)
	var lines_container := Control.new()
	lines_container.name = "MapLines"
	lines_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	lines_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lines_container)

	# Calculate map center
	var screen_center: Vector2 = Vector2(960, 540)  # 1920x1080 / 2
	var max_tier: int = 0
	for room in GameManager.all_rooms:
		if room.tier > max_tier:
			max_tier = room.tier

	var map_top: float = screen_center.y - (max_tier * TIER_SPACING) / 2.0

	# Group rooms by tier
	var tiers: Dictionary = {}
	for room in GameManager.all_rooms:
		if not tiers.has(room.tier):
			tiers[room.tier] = []
		tiers[room.tier].append(room)

	# Create room nodes
	var room_positions: Dictionary = {}  # room_id -> Vector2
	for tier_idx in tiers:
		var rooms_in_tier: Array = tiers[tier_idx]
		var tier_y: float = map_top + (max_tier - tier_idx) * TIER_SPACING + 60
		var tier_width: float = (rooms_in_tier.size() - 1) * 200.0
		var start_x: float = screen_center.x - tier_width / 2.0

		for i in range(rooms_in_tier.size()):
			var room: RoomData = rooms_in_tier[i]
			var pos := Vector2(start_x + i * 200.0, tier_y)
			room_positions[room.room_id] = pos
			_create_room_node(room, pos)

	# Draw connection lines
	_draw_connections(lines_container, room_positions)

	# Update button states
	_refresh_button_states()

func _create_room_node(room: RoomData, pos: Vector2) -> void:
	var btn := Button.new()
	btn.name = "Room_" + room.room_id

	# Style based on room type
	var type_icon: String = ""
	var bg_color: Color
	var border_color: Color
	var btn_size: Vector2
	var corner_radius: int
	var border_width: int
	match room.room_type:
		RoomData.RoomType.COMBAT:
			type_icon = "[Combat] "
			bg_color = Color(0.12, 0.14, 0.22)
			border_color = Color(0.3, 0.35, 0.50)
			btn_size = Vector2(150, 60)
			corner_radius = 4
			border_width = 2
		RoomData.RoomType.ELITE:
			type_icon = "[Elite] "
			bg_color = Color(0.22, 0.10, 0.15)
			border_color = Color(0.55, 0.2, 0.35)
			btn_size = Vector2(170, 75)
			corner_radius = 6
			border_width = 3
		RoomData.RoomType.REST:
			type_icon = "[Rest] "
			bg_color = Color(0.08, 0.18, 0.12)
			border_color = Color(0.2, 0.45, 0.3)
			btn_size = Vector2(140, 65)
			corner_radius = 20
			border_width = 1
		RoomData.RoomType.BOSS:
			type_icon = "[Boss] "
			bg_color = Color(0.28, 0.12, 0.04)
			border_color = Color(0.65, 0.3, 0.1)
			btn_size = Vector2(190, 85)
			corner_radius = 0
			border_width = 4
		_:
			type_icon = ""
			bg_color = Color(0.12, 0.14, 0.22)
			border_color = Color(0.3, 0.35, 0.50)
			btn_size = Vector2(150, 60)
			corner_radius = 4
			border_width = 2

	btn.custom_minimum_size = btn_size
	btn.position = pos - btn_size * 0.5

	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_content_margin_all(8)
	if room.room_type == RoomData.RoomType.ELITE:
		style.corner_radius_top_left = 16
		style.corner_radius_top_right = 16
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
	else:
		style.set_corner_radius_all(corner_radius)
	btn.add_theme_stylebox_override("normal", style)

	var hover_style := style.duplicate() as StyleBoxFlat
	hover_style.bg_color = bg_color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = bg_color.lightened(0.25)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	var disabled_style := style.duplicate() as StyleBoxFlat
	disabled_style.bg_color = bg_color.darkened(0.3)
	disabled_style.border_color = border_color.darkened(0.4)
	btn.add_theme_stylebox_override("disabled", disabled_style)

	btn.text = type_icon + room.display_name
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75))
	btn.tooltip_text = room.description

	# Add procedural icon
	var icon_tex := _make_room_icon(room.room_type, border_color)
	if icon_tex:
		var icon_rect := TextureRect.new()
		icon_rect.texture = icon_tex
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		icon_rect.position = Vector2(8, (btn_size.y - 14) * 0.5)
		icon_rect.size = Vector2(14, 14)
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(icon_rect)
		style.content_margin_left = 26

	btn.pressed.connect(func() -> void: _on_room_clicked(room))
	add_child(btn)
	room_buttons[room.room_id] = btn

func _make_room_icon(room_type: RoomData.RoomType, accent: Color) -> ImageTexture:
	var size: int = 12
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	match room_type:
		RoomData.RoomType.COMBAT:
			# Crossed swords
			for i in range(size):
				if i < size:
					img.set_pixel(i, i, accent)
					if i + 1 < size:
						img.set_pixel(i + 1 if i + 1 < size else i, i, accent)
				var mx: int = size - 1 - i
				if mx >= 0 and mx < size:
					img.set_pixel(mx, i, accent)
					if mx - 1 >= 0:
						img.set_pixel(mx - 1, i, accent)
		RoomData.RoomType.ELITE:
			# Six-pointed star
			var cx: float = size / 2.0
			var cy: float = size / 2.0
			for x in range(size):
				for y in range(size):
					var dx: float = absf(float(x) - cx)
					var dy: float = absf(float(y) - cy)
					if dx + dy * 1.5 < 5.0 or dy + dx * 1.5 < 5.0:
						img.set_pixel(x, y, accent)
		RoomData.RoomType.REST:
			# Campfire
			var cx: int = size / 2
			# Flame (top half)
			for x in range(size):
				for y in range(0, size / 2 + 2):
					var dx: float = absf(float(x) - float(cx))
					var flame_w: float = (1.0 - float(y) / float(size / 2 + 2)) * 3.5
					if dx < flame_w:
						var warm := accent.lightened(0.2)
						img.set_pixel(x, y, warm)
			# Logs (bottom)
			for x in range(2, size - 2):
				img.set_pixel(x, size - 3, accent.darkened(0.3))
				img.set_pixel(x, size - 2, accent.darkened(0.4))
		RoomData.RoomType.BOSS:
			# Crown
			var prong_xs := [2, 5, 8]
			var prong_hs := [7, 9, 7]
			for p_idx in range(3):
				var px: int = prong_xs[p_idx]
				var ph: int = prong_hs[p_idx]
				for y in range(size - ph, size - 2):
					img.set_pixel(px, y, accent)
					if px + 1 < size:
						img.set_pixel(px + 1, y, accent)
			# Base bar
			for x in range(1, size - 1):
				img.set_pixel(x, size - 2, accent)
				img.set_pixel(x, size - 1, accent.darkened(0.2))
		_:
			return null
	return ImageTexture.create_from_image(img)

func _draw_connections(container: Control, positions: Dictionary) -> void:
	for room in GameManager.all_rooms:
		for conn_id in room.connections:
			if positions.has(room.room_id) and positions.has(conn_id):
				var from: Vector2 = positions[room.room_id]
				var to: Vector2 = positions[conn_id]
				var curve_points := _bezier_curve(from, to, 12)

				var both_completed: bool = room.room_id in GameManager.completed_rooms and conn_id in GameManager.completed_rooms

				# Glow underlay
				var glow := Line2D.new()
				for pt in curve_points:
					glow.add_point(pt)
				glow.width = 6.0
				glow.default_color = Color(0.4, 0.35, 0.25, 0.08) if both_completed else Color(0.3, 0.35, 0.45, 0.06)
				container.add_child(glow)

				# Main line with gradient
				var line := Line2D.new()
				for pt in curve_points:
					line.add_point(pt)
				line.width = 2.0
				var grad := Gradient.new()
				if both_completed:
					grad.set_color(0, Color(0.6, 0.5, 0.25, 0.4))
					grad.set_color(1, Color(0.6, 0.5, 0.25, 0.7))
				else:
					grad.set_color(0, Color(0.3, 0.35, 0.45, 0.3))
					grad.set_color(1, Color(0.3, 0.35, 0.45, 0.7))
				line.gradient = grad
				container.add_child(line)

func _bezier_curve(from: Vector2, to: Vector2, segments: int) -> PackedVector2Array:
	var mid := (from + to) * 0.5
	var dx: float = to.x - from.x
	var control := mid + Vector2(signf(dx + 0.01) * 40.0, 0.0)
	var points := PackedVector2Array()
	for i in range(segments + 1):
		var t: float = float(i) / float(segments)
		var a: Vector2 = from.lerp(control, t)
		var b: Vector2 = control.lerp(to, t)
		points.append(a.lerp(b, t))
	return points

func _refresh_button_states() -> void:
	for room in GameManager.all_rooms:
		var btn: Button = room_buttons.get(room.room_id)
		if btn == null:
			continue

		_stop_room_button_pulse(room.room_id)

		if room.room_id in GameManager.completed_rooms:
			# Completed — dimmed
			btn.modulate = Color(0.4, 0.5, 0.4, 0.7)
			btn.disabled = true
		elif GameManager.is_room_available(room):
			# Available — glowing
			btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
			btn.disabled = false
			_start_room_button_pulse(room.room_id, btn)
		else:
			# Locked
			btn.modulate = Color(0.3, 0.3, 0.3, 0.5)
			btn.disabled = true

func _on_room_clicked(room: RoomData) -> void:
	if _room_selection_locked:
		return
	if not GameManager.is_room_available(room):
		return

	if room.room_type == RoomData.RoomType.REST:
		# Show rest screen overlay with heal/upgrade choice.
		var rest_scene: PackedScene = load("res://scenes/ui/rest_screen.tscn")
		var rest_screen: RestScreen = rest_scene.instantiate() as RestScreen
		if rest_screen == null:
			return
		_room_selection_locked = true
		_active_rest_screen = rest_screen
		add_child(rest_screen)
		rest_screen.rest_completed.connect(func() -> void:
			GameManager.enter_room(room)
			_refresh_button_states()
		)
		rest_screen.tree_exited.connect(func() -> void:
			if _active_rest_screen == rest_screen:
				_active_rest_screen = null
				_room_selection_locked = false
		)
	else:
		_room_selection_locked = true
		GameManager.enter_room(room)

func _on_room_completed(_room_id: String) -> void:
	_refresh_button_states()

func _start_room_button_pulse(room_id: String, btn: Button) -> void:
	var tween: Tween = btn.create_tween().set_loops()
	tween.tween_property(btn, "modulate:a", 0.7, 0.6)
	tween.tween_property(btn, "modulate:a", 1.0, 0.6)
	room_button_pulses[room_id] = tween

func _stop_room_button_pulse(room_id: String) -> void:
	var tween: Tween = room_button_pulses.get(room_id) as Tween
	if tween and tween.is_valid():
		tween.kill()
	room_button_pulses.erase(room_id)

func _clear_room_button_pulses() -> void:
	for room_id in room_button_pulses.keys():
		_stop_room_button_pulse(room_id)
