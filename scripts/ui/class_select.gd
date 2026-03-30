extends Control

## Class selection screen.
## Stores the chosen class config into GameManager and then enters gameplay.
## Enhanced with fire background, animated title, and glowing class buttons.

const SOLDIER_CONFIG_PATH := "res://resources/classes/soldier.tres"
const ROGUE_CONFIG_PATH := "res://resources/classes/rogue.tres"
const MAGE_CONFIG_PATH := "res://resources/classes/mage.tres"

const ROOT_VBOX_NODE := "VBoxContainer"
const TITLE_NODE := "Title"
const SUBTITLE_NODE := "Subtitle"
const DESCRIPTION_NODE := "Description"
const SOLDIER_BUTTON_NODE := "SoldierButton"
const ROGUE_BUTTON_NODE := "RogueButton"
const MAGE_BUTTON_NODE := "MageButton"

## Button/label references from this scene.
@onready var soldier_btn: Button = $VBoxContainer/SoldierButton
@onready var rogue_btn: Button = $VBoxContainer/RogueButton
@onready var mage_btn: Button = $VBoxContainer/MageButton
@onready var description_label: Label = $VBoxContainer/Description
@onready var title_label: Label = $VBoxContainer/Title
@onready var subtitle_label: Label = $VBoxContainer/Subtitle
@onready var background: ColorRect = $Background

# Class colors for button glow effects
const CLASS_COLORS := {
	"soldier": Color(0.3, 0.5, 1.0),
	"rogue": Color(0.2, 0.9, 0.4),
	"mage": Color(0.7, 0.3, 1.0),
}

var _title_time: float = 0.0
var _ember_particles: Array[Dictionary] = []
var _is_selecting: bool = false

func _ready() -> void:
	# Defensive reset in case the previous scene left the tree paused.
	if get_tree().paused:
		GameManager.toggle_pause()
	_ensure_ui_nodes()
	_rebind_ui_refs()
	if not _has_required_ui():
		push_error("ClassSelect: required UI nodes are missing")
		return

	# Apply fire shader to background
	_setup_fire_background()

	# Style the buttons with dark themed look
	_style_class_buttons()

	# Initialize floating ember particles
	_init_embers()

	# Wire each button using anonymous lambdas; keeps signal hookup local and compact.
	soldier_btn.pressed.connect(func(): _select_class(SOLDIER_CONFIG_PATH))
	rogue_btn.pressed.connect(func(): _select_class(ROGUE_CONFIG_PATH))
	mage_btn.pressed.connect(func(): _select_class(MAGE_CONFIG_PATH))

	# Show flavor text as the user highlights a class.
	soldier_btn.focus_entered.connect(func():
		_show_description("Soldier: Melee fighter with high HP. Gains lots of mana from taking hits. Powerful close-range card abilities.")
		_pulse_button(soldier_btn, CLASS_COLORS["soldier"]))
	rogue_btn.focus_entered.connect(func():
		_show_description("Rogue: Fast mid-range attacker. Low card costs for rapid play. Hit-and-run specialist.")
		_pulse_button(rogue_btn, CLASS_COLORS["rogue"]))
	mage_btn.focus_entered.connect(func():
		_show_description("Mage: Long-range caster. Weak basic attack but massive card chain combos. High mana pool.")
		_pulse_button(mage_btn, CLASS_COLORS["mage"]))

	# Mouse hover support for button glow
	soldier_btn.mouse_entered.connect(func(): _pulse_button(soldier_btn, CLASS_COLORS["soldier"]))
	rogue_btn.mouse_entered.connect(func(): _pulse_button(rogue_btn, CLASS_COLORS["rogue"]))
	mage_btn.mouse_entered.connect(func(): _pulse_button(mage_btn, CLASS_COLORS["mage"]))

	soldier_btn.grab_focus()

func _process(delta: float) -> void:
	if not _has_required_ui():
		return
	_title_time += delta

	# Animate title color - fiery shimmer
	var t := sin(_title_time * 2.0) * 0.5 + 0.5
	var title_color := Color(1.0, 0.6 + t * 0.3, 0.1 + t * 0.15, 1.0)
	title_label.add_theme_color_override("font_color", title_color)

	# Subtle title scale pulse
	var scale_pulse := 1.0 + sin(_title_time * 1.5) * 0.02
	title_label.pivot_offset = title_label.size / 2.0
	title_label.scale = Vector2(scale_pulse, scale_pulse)

	# Animate subtitle with cooler tone
	var sub_t := sin(_title_time * 1.2 + 1.0) * 0.5 + 0.5
	subtitle_label.add_theme_color_override("font_color", Color(0.5 + sub_t * 0.2, 0.5 + sub_t * 0.1, 0.6 + sub_t * 0.15, 1.0))

	# Update ember particles
	_update_embers(delta)
	queue_redraw()

func _draw() -> void:
	# Draw floating ember particles over everything
	for ember in _ember_particles:
		var alpha: float = ember["life"] * ember["max_alpha"]
		var col := Color(ember["color"].r, ember["color"].g, ember["color"].b, alpha)
		var r: float = ember["radius"]
		draw_circle(ember["pos"], r, col)
		# Inner bright core
		if r > 1.5:
			draw_circle(ember["pos"], r * 0.4, Color(1.0, 0.9, 0.7, alpha * 0.6))

func _setup_fire_background() -> void:
	if background == null:
		return
	var shader := load("res://shaders/fire_bg.gdshader") as Shader
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("speed", 0.6)
		mat.set_shader_parameter("intensity", 0.45)
		mat.set_shader_parameter("fire_color_hot", Color(1.0, 0.6, 0.1, 1.0))
		mat.set_shader_parameter("fire_color_mid", Color(0.8, 0.15, 0.05, 1.0))
		mat.set_shader_parameter("fire_color_cool", Color(0.12, 0.02, 0.0, 1.0))
		mat.set_shader_parameter("base_color", Color(0.04, 0.03, 0.08, 1.0))
		background.material = mat

func _style_class_buttons() -> void:
	for btn in _get_class_buttons():
		if btn == null:
			continue
		# Normal state - dark with subtle border
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color(0.08, 0.08, 0.14, 0.9)
		normal.border_color = Color(0.4, 0.3, 0.2, 0.6)
		normal.set_border_width_all(2)
		normal.set_corner_radius_all(8)
		normal.set_content_margin_all(12)
		btn.add_theme_stylebox_override("normal", normal)

		# Hover state - warmer glow
		var hover := StyleBoxFlat.new()
		hover.bg_color = Color(0.12, 0.1, 0.16, 0.95)
		hover.border_color = Color(1.0, 0.5, 0.2, 0.8)
		hover.set_border_width_all(3)
		hover.set_corner_radius_all(8)
		hover.set_content_margin_all(12)
		btn.add_theme_stylebox_override("hover", hover)

		# Pressed state - bright flash
		var pressed := StyleBoxFlat.new()
		pressed.bg_color = Color(0.2, 0.12, 0.08, 0.95)
		pressed.border_color = Color(1.0, 0.7, 0.3, 1.0)
		pressed.set_border_width_all(3)
		pressed.set_corner_radius_all(8)
		pressed.set_content_margin_all(12)
		btn.add_theme_stylebox_override("pressed", pressed)

		# Focus state - matches hover
		var focus := StyleBoxFlat.new()
		focus.bg_color = Color(0.12, 0.1, 0.16, 0.95)
		focus.border_color = Color(1.0, 0.5, 0.2, 0.8)
		focus.set_border_width_all(3)
		focus.set_corner_radius_all(8)
		focus.set_content_margin_all(12)
		btn.add_theme_stylebox_override("focus", focus)

		btn.add_theme_color_override("font_color", Color(0.9, 0.85, 0.8, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.8, 0.5, 1.0))
		btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.9, 0.6, 1.0))
		btn.add_theme_color_override("font_focus_color", Color(1.0, 0.8, 0.5, 1.0))

func _pulse_button(btn: Button, color: Color) -> void:
	if btn == null:
		return
	# Quick scale punch on focus/hover
	var tween := create_tween()
	tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_IN)

	# Update border color to class color
	for style_name in ["hover", "focus"]:
		var style: StyleBoxFlat = btn.get_theme_stylebox(style_name) as StyleBoxFlat
		if style:
			style.border_color = Color(color.r, color.g, color.b, 0.9)

func _init_embers() -> void:
	for i in range(30):
		_ember_particles.append(_create_ember())

func _create_ember() -> Dictionary:
	var vp_size := get_viewport_rect().size
	return {
		"pos": Vector2(randf() * vp_size.x, vp_size.y + randf() * 100.0),
		"vel": Vector2(randf_range(-20.0, 20.0), randf_range(-80.0, -180.0)),
		"life": randf(),
		"max_alpha": randf_range(0.3, 0.8),
		"radius": randf_range(1.0, 3.5),
		"color": Color(1.0, randf_range(0.3, 0.7), randf_range(0.0, 0.2)),
		"wobble_speed": randf_range(2.0, 5.0),
		"wobble_amp": randf_range(10.0, 30.0),
		"age": randf() * TAU,
	}

func _update_embers(delta: float) -> void:
	for i in range(_ember_particles.size()):
		var ember := _ember_particles[i]
		ember["age"] += delta
		ember["pos"].x += ember["vel"].x * delta + sin(ember["age"] * ember["wobble_speed"]) * ember["wobble_amp"] * delta
		ember["pos"].y += ember["vel"].y * delta
		ember["life"] -= delta * 0.3

		# Respawn if dead or off screen
		if ember["life"] <= 0.0 or ember["pos"].y < -20.0:
			_ember_particles[i] = _create_ember()

func _show_description(text: String) -> void:
	if description_label == null:
		return
	# Update one shared label instead of creating labels per button.
	description_label.text = text

	# Fade in effect
	description_label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(description_label, "modulate:a", 1.0, 0.2)

func _select_class(config_path: String) -> void:
	if _is_selecting:
		return
	# Loading a resource by path lets designers tune stats in external `.tres` files.
	var config := load(config_path) as ClassConfig
	if config == null:
		push_error("Failed to load class config: " + config_path)
		return
	_is_selecting = true
	for btn in _get_class_buttons():
		if btn == null:
			continue
		btn.disabled = true

	# Flash effect on selection
	var flash := ColorRect.new()
	flash.color = Color(1.0, 0.8, 0.3, 0.5)
	flash.anchors_preset = Control.PRESET_FULL_RECT
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)

	var tween := create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.3)
	tween.tween_callback(func():
		GameManager.current_class_config = config
		GameManager.start_new_run()
		GameManager.go_to_map())

func _ensure_ui_nodes() -> void:
	var root_box: VBoxContainer = get_node_or_null(ROOT_VBOX_NODE) as VBoxContainer
	if root_box == null:
		root_box = VBoxContainer.new()
		root_box.name = ROOT_VBOX_NODE
		root_box.set_anchors_preset(Control.PRESET_CENTER)
		root_box.position = Vector2(-260, -220)
		root_box.size = Vector2(520, 440)
		root_box.alignment = BoxContainer.ALIGNMENT_CENTER
		root_box.add_theme_constant_override("separation", 18)
		add_child(root_box)

	_ensure_label(root_box, TITLE_NODE, "CLASS SELECT", 36, Color(1.0, 0.85, 0.4), true)
	_ensure_label(root_box, SUBTITLE_NODE, "Choose your champion", 18, Color(0.75, 0.75, 0.85), true)
	_ensure_button(root_box, SOLDIER_BUTTON_NODE, "Soldier")
	_ensure_button(root_box, ROGUE_BUTTON_NODE, "Rogue")
	_ensure_button(root_box, MAGE_BUTTON_NODE, "Mage")
	var description: Label = _ensure_label(root_box, DESCRIPTION_NODE, "Select a class to begin your run.", 16, Color(0.8, 0.8, 0.8), true)
	description.custom_minimum_size = Vector2(460, 90)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD

func _ensure_button(parent: VBoxContainer, node_name: String, text: String) -> Button:
	var btn: Button = parent.get_node_or_null(node_name) as Button
	if btn == null:
		btn = Button.new()
		btn.name = node_name
		btn.text = text
		btn.custom_minimum_size = Vector2(320, 54)
		btn.focus_mode = Control.FOCUS_ALL
		parent.add_child(btn)
	return btn

func _ensure_label(parent: VBoxContainer, node_name: String, text: String, font_size: int, font_color: Color, centered: bool = false) -> Label:
	var label: Label = parent.get_node_or_null(node_name) as Label
	if label == null:
		label = Label.new()
		label.name = node_name
		parent.add_child(label)
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	if centered:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

func _rebind_ui_refs() -> void:
	soldier_btn = get_node_or_null("%s/%s" % [ROOT_VBOX_NODE, SOLDIER_BUTTON_NODE]) as Button
	rogue_btn = get_node_or_null("%s/%s" % [ROOT_VBOX_NODE, ROGUE_BUTTON_NODE]) as Button
	mage_btn = get_node_or_null("%s/%s" % [ROOT_VBOX_NODE, MAGE_BUTTON_NODE]) as Button
	description_label = get_node_or_null("%s/%s" % [ROOT_VBOX_NODE, DESCRIPTION_NODE]) as Label
	title_label = get_node_or_null("%s/%s" % [ROOT_VBOX_NODE, TITLE_NODE]) as Label
	subtitle_label = get_node_or_null("%s/%s" % [ROOT_VBOX_NODE, SUBTITLE_NODE]) as Label
	background = get_node_or_null("Background") as ColorRect

func _get_class_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	if soldier_btn != null:
		buttons.append(soldier_btn)
	if rogue_btn != null:
		buttons.append(rogue_btn)
	if mage_btn != null:
		buttons.append(mage_btn)
	return buttons

func _has_required_ui() -> bool:
	return background != null and title_label != null and subtitle_label != null and description_label != null and _get_class_buttons().size() == 3
