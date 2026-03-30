extends Control

## Hades/Slay-the-Spire style overworld map.
## Draws room nodes vertically with connecting lines.
## Clicking an available room enters combat.

const TIER_SPACING: float = 160.0
const NODE_RADIUS: float = 28.0

var room_buttons: Dictionary = {}  # room_id -> Button
var room_button_pulses: Dictionary = {}  # room_id -> Tween

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
	btn.custom_minimum_size = Vector2(160, 70)
	btn.position = pos - Vector2(80, 35)

	# Style based on room type
	var type_icon: String = ""
	var bg_color: Color
	var border_color: Color
	match room.room_type:
		RoomData.RoomType.COMBAT:
			type_icon = "[Combat] "
			bg_color = Color(0.12, 0.14, 0.22)
			border_color = Color(0.3, 0.35, 0.50)
		RoomData.RoomType.ELITE:
			type_icon = "[Elite] "
			bg_color = Color(0.22, 0.10, 0.15)
			border_color = Color(0.55, 0.2, 0.35)
		RoomData.RoomType.REST:
			type_icon = "[Rest] "
			bg_color = Color(0.08, 0.18, 0.12)
			border_color = Color(0.2, 0.45, 0.3)
		RoomData.RoomType.BOSS:
			type_icon = "[Boss] "
			bg_color = Color(0.28, 0.12, 0.04)
			border_color = Color(0.65, 0.3, 0.1)

	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(8)
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

	btn.pressed.connect(func() -> void: _on_room_clicked(room))
	add_child(btn)
	room_buttons[room.room_id] = btn

func _draw_connections(container: Control, positions: Dictionary) -> void:
	for room in GameManager.all_rooms:
		for conn_id in room.connections:
			if positions.has(room.room_id) and positions.has(conn_id):
				var from: Vector2 = positions[room.room_id]
				var to: Vector2 = positions[conn_id]
				var line := Line2D.new()
				line.add_point(from)
				line.add_point(to)
				line.width = 2.0
				line.default_color = Color(0.3, 0.35, 0.45, 0.6)
				container.add_child(line)

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
	if not GameManager.is_room_available(room):
		return

	if room.room_type == RoomData.RoomType.REST:
		# Show rest screen overlay with heal/upgrade choice.
		var rest_scene: PackedScene = load("res://scenes/ui/rest_screen.tscn")
		var rest_screen: RestScreen = rest_scene.instantiate() as RestScreen
		if rest_screen == null:
			return
		add_child(rest_screen)
		rest_screen.rest_completed.connect(func() -> void:
			GameManager.enter_room(room)
			_refresh_button_states()
		)
	else:
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
