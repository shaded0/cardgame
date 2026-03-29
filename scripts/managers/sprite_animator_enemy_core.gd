extends RefCounted

const Draw = preload("res://scripts/managers/sprite_animator_draw.gd")

static func create_slime_frames(body_color: Color) -> SpriteFrames:
	var frames := Draw.new_frames()
	var light := body_color.lightened(0.2)
	var dark := body_color.darkened(0.2)

	frames.add_animation(&"idle")
	frames.set_animation_speed(&"idle", 3.0)
	frames.set_animation_loop(&"idle", true)
	for i in range(4):
		var squish: float = sin(i * PI / 2.0) * 2.0
		frames.add_frame(&"idle", _draw_slime_frame(48, body_color, light, dark, squish, 0.0))

	frames.add_animation(&"run")
	frames.set_animation_speed(&"run", 6.0)
	frames.set_animation_loop(&"run", true)
	for i in range(4):
		var bounce: float = -absf(sin(i * PI / 2.0)) * 4.0
		var squish: float = sin(i * PI / 2.0) * 3.0
		frames.add_frame(&"run", _draw_slime_frame(48, body_color, light, dark, squish, bounce))

	frames.add_animation(&"attack")
	frames.set_animation_speed(&"attack", 6.0)
	frames.set_animation_loop(&"attack", false)
	var lunge_offsets: Array = [0.0, -5.0, -2.0]
	var lunge_squish: Array = [0.0, -3.0, 1.0]
	for i in range(3):
		frames.add_frame(&"attack", _draw_slime_frame(48, body_color, light, dark, lunge_squish[i], lunge_offsets[i]))

	return frames

static func create_skeleton_frames() -> SpriteFrames:
	var frames := Draw.new_frames()
	var bone := Color(0.85, 0.82, 0.75)
	var dark := Color(0.5, 0.45, 0.4)
	var metal := Color(0.6, 0.65, 0.7)

	frames.add_animation(&"idle")
	frames.set_animation_speed(&"idle", 3.0)
	frames.set_animation_loop(&"idle", true)
	for i in range(4):
		var bob: float = sin(i * PI / 2.0) * 1.0
		frames.add_frame(&"idle", _draw_skeleton_frame(48, bone, dark, metal, bob, 0.0))

	frames.add_animation(&"run")
	frames.set_animation_speed(&"run", 8.0)
	frames.set_animation_loop(&"run", true)
	for i in range(4):
		var phase: float = float(i) / 4.0 * TAU
		var leg: float = sin(phase) * 3.0
		var bob: float = absf(sin(phase)) * -1.5
		frames.add_frame(&"run", _draw_skeleton_frame(48, bone, dark, metal, bob, leg))

	frames.add_animation(&"attack")
	frames.set_animation_speed(&"attack", 8.0)
	frames.set_animation_loop(&"attack", false)
	for i in range(3):
		var swing: float = float(i) / 2.0
		frames.add_frame(&"attack", _draw_skeleton_attack_frame(48, bone, dark, metal, swing))

	return frames

static func create_imp_frames() -> SpriteFrames:
	var frames := Draw.new_frames()

	frames.add_animation(&"idle")
	frames.set_animation_speed(&"idle", 4.0)
	frames.set_animation_loop(&"idle", true)
	for i in range(4):
		var hover: float = sin(i * PI / 2.0) * 2.0
		frames.add_frame(&"idle", _draw_imp_frame(48, hover, 0.0))

	frames.add_animation(&"run")
	frames.set_animation_speed(&"run", 8.0)
	frames.set_animation_loop(&"run", true)
	for i in range(4):
		var hover: float = sin(i * PI / 2.0) * 3.0
		var wobble: float = sin(i * PI / 2.0 + PI) * 2.0
		frames.add_frame(&"run", _draw_imp_frame(48, hover, wobble))

	frames.add_animation(&"attack")
	frames.set_animation_speed(&"attack", 8.0)
	frames.set_animation_loop(&"attack", false)
	for i in range(3):
		var glow: float = float(i) / 2.0
		frames.add_frame(&"attack", _draw_imp_attack_frame(48, glow))

	return frames

static func create_wraith_frames() -> SpriteFrames:
	var frames := Draw.new_frames()

	frames.add_animation(&"idle")
	frames.set_animation_speed(&"idle", 3.0)
	frames.set_animation_loop(&"idle", true)
	for i in range(4):
		var sway: float = sin(i * PI / 2.0) * 2.0
		var hover: float = sin(i * PI / 2.0 + PI / 4.0) * 1.5
		frames.add_frame(&"idle", _draw_wraith_frame(48, sway, hover))

	frames.add_animation(&"run")
	frames.set_animation_speed(&"run", 6.0)
	frames.set_animation_loop(&"run", true)
	for i in range(4):
		var sway: float = sin(i * PI / 2.0) * 3.0
		var hover: float = sin(i * PI / 2.0) * -3.0
		frames.add_frame(&"run", _draw_wraith_frame(48, sway, hover))

	frames.add_animation(&"attack")
	frames.set_animation_speed(&"attack", 6.0)
	frames.set_animation_loop(&"attack", false)
	for i in range(3):
		var lunge: float = float(i) / 2.0 * -4.0
		frames.add_frame(&"attack", _draw_wraith_frame(48, 0.0, lunge))

	return frames

static func create_golem_frames() -> SpriteFrames:
	var frames := Draw.new_frames()

	frames.add_animation(&"idle")
	frames.set_animation_speed(&"idle", 2.0)
	frames.set_animation_loop(&"idle", true)
	for i in range(4):
		var bob: float = sin(i * PI / 2.0) * 1.0
		frames.add_frame(&"idle", _draw_golem_frame(48, bob, 0.0))

	frames.add_animation(&"run")
	frames.set_animation_speed(&"run", 4.0)
	frames.set_animation_loop(&"run", true)
	for i in range(4):
		var phase: float = float(i) / 4.0 * TAU
		var leg: float = sin(phase) * 2.0
		var bob: float = absf(sin(phase)) * -2.0
		frames.add_frame(&"run", _draw_golem_frame(48, bob, leg))

	frames.add_animation(&"attack")
	frames.set_animation_speed(&"attack", 5.0)
	frames.set_animation_loop(&"attack", false)
	for i in range(3):
		var slam: float = float(i) / 2.0
		frames.add_frame(&"attack", _draw_golem_attack_frame(48, slam))

	return frames

static func _draw_slime_frame(size: int, body_color: Color, light: Color, dark: Color, squish: float, y_offset: float) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0
	var cy: float = size / 2.0 + y_offset
	var s: float = size / 48.0
	var rx: float = 12 * s + squish * 0.5
	var ry: float = 10 * s - squish * 0.3

	Draw.fill_circle(image, cx, size / 2.0 + 10 * s, 9 * s, Color(0, 0, 0, 0.12))
	Draw.fill_circle(image, cx, cy + 2 * s, rx, body_color)
	Draw.fill_circle(image, cx, cy - 2 * s + squish * 0.3, ry, light)
	Draw.fill_circle(image, cx - 3 * s, cy - 5 * s + squish * 0.2, 3 * s, light.lightened(0.3))
	Draw.fill_circle(image, cx - 4 * s, cy - 6 * s + squish * 0.2, 1.5 * s, Color(1, 1, 1, 0.4))
	Draw.fill_circle(image, cx - 4 * s, cy - 3 * s, 3 * s, Color.WHITE)
	Draw.fill_circle(image, cx + 4 * s, cy - 3 * s, 3 * s, Color.WHITE)
	Draw.fill_circle(image, cx - 4 * s, cy - 3.5 * s, 1.5 * s, Color(0.1, 0.1, 0.1))
	Draw.fill_circle(image, cx + 4 * s, cy - 3.5 * s, 1.5 * s, Color(0.1, 0.1, 0.1))
	Draw.fill_rect(image, cx - 2 * s, cy + 2 * s, 4 * s, 1.5 * s, dark.darkened(0.3))
	return ImageTexture.create_from_image(image)

static func _draw_skeleton_frame(size: int, bone: Color, dark: Color, metal: Color, bob: float, leg_offset: float) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0
	var cy: float = size / 2.0
	var s: float = size / 48.0

	Draw.fill_circle(image, cx, cy + 14 * s, 8 * s, Color(0, 0, 0, 0.1))
	Draw.fill_rect(image, cx - 4 * s, cy + 6 * s + leg_offset, 2 * s, 10 * s, bone)
	Draw.fill_rect(image, cx + 2 * s, cy + 6 * s - leg_offset, 2 * s, 10 * s, bone)
	Draw.fill_circle(image, cx - 3 * s, cy + 6 * s + leg_offset, 2 * s, dark)
	Draw.fill_circle(image, cx + 3 * s, cy + 6 * s - leg_offset, 2 * s, dark)
	Draw.fill_rect(image, cx - 5 * s, cy - 2 * s + bob, 10 * s, 2 * s, bone)
	Draw.fill_rect(image, cx - 4 * s, cy + 1 * s + bob, 8 * s, 2 * s, bone.darkened(0.1))
	Draw.fill_rect(image, cx - 3 * s, cy + 4 * s + bob, 6 * s, 1 * s, bone.darkened(0.15))
	Draw.fill_rect(image, cx - 1 * s, cy - 3 * s + bob, 2 * s, 10 * s, dark)
	Draw.fill_circle(image, cx - 6 * s, cy - 2 * s + bob, 2.5 * s, bone)
	Draw.fill_circle(image, cx + 6 * s, cy - 2 * s + bob, 2.5 * s, bone)
	Draw.fill_rect(image, cx - 8 * s, cy - 1 * s + bob, 2 * s, 8 * s, bone)
	Draw.fill_rect(image, cx + 6 * s, cy - 1 * s + bob, 2 * s, 8 * s, bone)
	Draw.fill_circle(image, cx, cy - 8 * s + bob, 6 * s, bone)
	Draw.fill_circle(image, cx - 3 * s, cy - 9 * s + bob, 2 * s, Color(0.1, 0.0, 0.0))
	Draw.fill_circle(image, cx + 3 * s, cy - 9 * s + bob, 2 * s, Color(0.1, 0.0, 0.0))
	Draw.fill_circle(image, cx - 3 * s, cy - 9 * s + bob, 1 * s, Color(0.8, 0.2, 0.1, 0.9))
	Draw.fill_circle(image, cx + 3 * s, cy - 9 * s + bob, 1 * s, Color(0.8, 0.2, 0.1, 0.9))
	Draw.fill_rect(image, cx - 3 * s, cy - 4 * s + bob, 6 * s, 2 * s, bone.darkened(0.15))
	Draw.fill_rect(image, cx + 8 * s, cy - 10 * s + bob, 2 * s, 10 * s, metal)
	Draw.fill_rect(image, cx + 7 * s, cy - 1 * s + bob, 4 * s, 2 * s, metal.darkened(0.2))
	return ImageTexture.create_from_image(image)

static func _draw_skeleton_attack_frame(size: int, bone: Color, dark: Color, metal: Color, swing: float) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0
	var cy: float = size / 2.0
	var s: float = size / 48.0
	var lean: float = -2.0 * swing
	var arm_ext: float = -6.0 * swing

	Draw.fill_circle(image, cx, cy + 14 * s, 8 * s, Color(0, 0, 0, 0.1))
	Draw.fill_rect(image, cx - 4 * s, cy + 6 * s, 2 * s, 10 * s, bone)
	Draw.fill_rect(image, cx + 2 * s, cy + 6 * s, 2 * s, 10 * s, bone)
	Draw.fill_rect(image, cx - 5 * s, cy - 2 * s + lean, 10 * s, 2 * s, bone)
	Draw.fill_rect(image, cx - 1 * s, cy - 3 * s + lean, 2 * s, 10 * s, dark)
	Draw.fill_circle(image, cx - 6 * s, cy - 2 * s + lean, 2.5 * s, bone)
	Draw.fill_circle(image, cx + 6 * s, cy - 2 * s + lean, 2.5 * s, bone)
	Draw.fill_rect(image, cx - 8 * s, cy - 1 * s + lean, 2 * s, 8 * s, bone)
	Draw.fill_rect(image, cx + 6 * s, cy - 1 * s + lean + arm_ext, 2 * s, 8 * s, bone)
	Draw.fill_circle(image, cx, cy - 8 * s + lean, 6 * s, bone)
	Draw.fill_circle(image, cx - 3 * s, cy - 9 * s + lean, 1 * s, Color(0.8, 0.2, 0.1, 0.9))
	Draw.fill_circle(image, cx + 3 * s, cy - 9 * s + lean, 1 * s, Color(0.8, 0.2, 0.1, 0.9))
	Draw.fill_rect(image, cx + 8 * s, cy - 14 * s + lean + arm_ext - swing * 6.0, 2 * s, 12 * s, metal)
	Draw.fill_rect(image, cx + 8 * s, cy - 15 * s + lean + arm_ext - swing * 6.0, 2 * s, 2 * s, Color(1, 1, 1, 0.6))
	return ImageTexture.create_from_image(image)

static func _draw_imp_frame(size: int, hover: float, wobble: float) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0 + wobble
	var cy: float = size / 2.0 + hover
	var s: float = size / 48.0
	var body := Color(0.9, 0.3, 0.1)
	var light := Color(1.0, 0.5, 0.2)
	var dark := Color(0.6, 0.15, 0.05)

	Draw.fill_circle(image, size / 2.0, size / 2.0 + 12 * s, 6 * s, Color(0, 0, 0, 0.1))
	Draw.fill_circle(image, cx, cy + 2 * s, 8 * s, body)
	Draw.fill_circle(image, cx, cy, 6 * s, light)
	Draw.fill_rect(image, cx - 6 * s, cy - 10 * s, 2 * s, 6 * s, dark)
	Draw.fill_rect(image, cx + 4 * s, cy - 10 * s, 2 * s, 6 * s, dark)
	Draw.fill_rect(image, cx - 7 * s, cy - 11 * s, 2 * s, 2 * s, dark.lightened(0.1))
	Draw.fill_rect(image, cx + 5 * s, cy - 11 * s, 2 * s, 2 * s, dark.lightened(0.1))
	Draw.fill_circle(image, cx - 3 * s, cy - 2 * s, 2.5 * s, Color(1.0, 0.9, 0.2))
	Draw.fill_circle(image, cx + 3 * s, cy - 2 * s, 2.5 * s, Color(1.0, 0.9, 0.2))
	Draw.fill_circle(image, cx - 3 * s, cy - 2 * s, 1 * s, Color(0.1, 0.0, 0.0))
	Draw.fill_circle(image, cx + 3 * s, cy - 2 * s, 1 * s, Color(0.1, 0.0, 0.0))
	Draw.fill_rect(image, cx - 4 * s, cy + 8 * s, 2 * s, 4 * s, dark)
	Draw.fill_rect(image, cx + 2 * s, cy + 8 * s, 2 * s, 4 * s, dark)
	Draw.fill_rect(image, cx + 6 * s, cy + 3 * s, 4 * s, 2 * s, dark)
	Draw.fill_rect(image, cx + 9 * s, cy + 2 * s, 2 * s, 2 * s, light)
	return ImageTexture.create_from_image(image)

static func _draw_imp_attack_frame(size: int, glow: float) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0
	var cy: float = size / 2.0
	var s: float = size / 48.0
	var body := Color(0.9, 0.3, 0.1)
	var light := Color(1.0, 0.5 + glow * 0.3, 0.2 + glow * 0.2)
	var eye_glow := Color(1.0, 0.9 + glow * 0.1, 0.2 + glow * 0.3)
	var orb_y: float = cy - 8 * s - glow * 4.0

	Draw.fill_circle(image, cx, cy + 2 * s, 8 * s, body)
	Draw.fill_circle(image, cx, cy, 6 * s, light)
	Draw.fill_rect(image, cx - 6 * s, cy - 10 * s, 2 * s, 6 * s, body.darkened(0.3))
	Draw.fill_rect(image, cx + 4 * s, cy - 10 * s, 2 * s, 6 * s, body.darkened(0.3))
	Draw.fill_circle(image, cx - 3 * s, cy - 2 * s, 3 * s, eye_glow)
	Draw.fill_circle(image, cx + 3 * s, cy - 2 * s, 3 * s, eye_glow)
	Draw.fill_circle(image, cx, orb_y, (3 + glow * 2) * s, Color(1.0, 0.6, 0.1, 0.8))
	Draw.fill_circle(image, cx, orb_y, (1.5 + glow) * s, Color(1.0, 1.0, 0.7, 0.6))
	Draw.fill_rect(image, cx - 4 * s, cy + 8 * s, 2 * s, 4 * s, body.darkened(0.3))
	Draw.fill_rect(image, cx + 2 * s, cy + 8 * s, 2 * s, 4 * s, body.darkened(0.3))
	return ImageTexture.create_from_image(image)

static func _draw_wraith_frame(size: int, sway: float, hover: float) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0 + sway
	var cy: float = size / 2.0 + hover
	var s: float = size / 48.0
	var body := Color(0.2, 0.08, 0.3, 0.8)
	var light := Color(0.35, 0.15, 0.5, 0.6)
	var wisp := Color(0.15, 0.05, 0.25, 0.4)

	Draw.fill_circle(image, cx, cy + 10 * s, 5 * s, wisp)
	Draw.fill_circle(image, cx - 2 * s, cy + 13 * s, 3 * s, Color(wisp.r, wisp.g, wisp.b, 0.2))
	Draw.fill_circle(image, cx + 2 * s, cy + 14 * s, 2 * s, Color(wisp.r, wisp.g, wisp.b, 0.15))
	Draw.fill_circle(image, cx, cy + 2 * s, 8 * s, body)
	Draw.fill_circle(image, cx, cy - 4 * s, 7 * s, light)
	Draw.fill_circle(image, cx, cy + 6 * s, 6 * s, wisp)
	Draw.fill_circle(image, cx, cy - 8 * s, 7 * s, body)
	Draw.fill_circle(image, cx, cy - 10 * s, 5 * s, Color(0.1, 0.03, 0.15, 0.9))
	Draw.fill_circle(image, cx - 3 * s, cy - 7 * s, 2 * s, Color(0.6, 0.1, 1.0, 0.9))
	Draw.fill_circle(image, cx + 3 * s, cy - 7 * s, 2 * s, Color(0.6, 0.1, 1.0, 0.9))
	Draw.fill_circle(image, cx - 3 * s, cy - 7 * s, 1 * s, Color(1.0, 0.5, 1.0, 0.7))
	Draw.fill_circle(image, cx + 3 * s, cy - 7 * s, 1 * s, Color(1.0, 0.5, 1.0, 0.7))
	Draw.fill_rect(image, cx - 10 * s, cy - 2 * s, 3 * s, 6 * s, wisp)
	Draw.fill_rect(image, cx + 7 * s, cy - 2 * s, 3 * s, 6 * s, wisp)
	Draw.fill_circle(image, cx - 9 * s, cy + 4 * s, 2 * s, light)
	Draw.fill_circle(image, cx + 9 * s, cy + 4 * s, 2 * s, light)
	return ImageTexture.create_from_image(image)

static func _draw_golem_frame(size: int, bob: float, leg_offset: float) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0
	var cy: float = size / 2.0
	var s: float = size / 48.0
	var stone := Color(0.5, 0.45, 0.4)
	var light := Color(0.6, 0.55, 0.5)
	var dark := Color(0.3, 0.25, 0.2)
	var crack := Color(0.8, 0.4, 0.1, 0.6)

	Draw.fill_circle(image, cx, cy + 14 * s, 10 * s, Color(0, 0, 0, 0.15))
	Draw.fill_rect(image, cx - 7 * s, cy + 4 * s + leg_offset, 5 * s, 10 * s, dark)
	Draw.fill_rect(image, cx + 2 * s, cy + 4 * s - leg_offset, 5 * s, 10 * s, dark)
	Draw.fill_rect(image, cx - 8 * s, cy + 12 * s + leg_offset, 7 * s, 3 * s, dark.darkened(0.2))
	Draw.fill_rect(image, cx + 1 * s, cy + 12 * s - leg_offset, 7 * s, 3 * s, dark.darkened(0.2))
	Draw.fill_rect(image, cx - 10 * s, cy - 8 * s + bob, 20 * s, 14 * s, stone)
	Draw.fill_rect(image, cx - 8 * s, cy - 6 * s + bob, 16 * s, 4 * s, light)
	Draw.fill_rect(image, cx - 3 * s, cy - 5 * s + bob, 1 * s, 8 * s, crack)
	Draw.fill_rect(image, cx + 4 * s, cy - 3 * s + bob, 1 * s, 6 * s, crack)
	Draw.fill_rect(image, cx - 14 * s, cy - 4 * s + bob, 5 * s, 14 * s, stone)
	Draw.fill_rect(image, cx + 9 * s, cy - 4 * s + bob, 5 * s, 14 * s, stone)
	Draw.fill_circle(image, cx - 12 * s, cy + 10 * s + bob, 4 * s, dark)
	Draw.fill_circle(image, cx + 12 * s, cy + 10 * s + bob, 4 * s, dark)
	Draw.fill_circle(image, cx, cy - 12 * s + bob, 6 * s, stone.lightened(0.1))
	Draw.fill_rect(image, cx - 4 * s, cy - 13 * s + bob, 3 * s, 2 * s, Color(0.9, 0.5, 0.1))
	Draw.fill_rect(image, cx + 1 * s, cy - 13 * s + bob, 3 * s, 2 * s, Color(0.9, 0.5, 0.1))
	Draw.fill_rect(image, cx - 5 * s, cy - 15 * s + bob, 10 * s, 2 * s, dark)
	return ImageTexture.create_from_image(image)

static func _draw_golem_attack_frame(size: int, slam: float) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0
	var cy: float = size / 2.0
	var s: float = size / 48.0
	var stone := Color(0.5, 0.45, 0.4)
	var light := Color(0.6, 0.55, 0.5)
	var dark := Color(0.3, 0.25, 0.2)
	var lean: float = -2.0 * slam
	var arm_raise: float = -10.0 * (1.0 - slam)
	var eye_bright := 0.5 + slam * 0.5

	Draw.fill_circle(image, cx, cy + 14 * s, 10 * s, Color(0, 0, 0, 0.15))
	Draw.fill_rect(image, cx - 7 * s, cy + 4 * s, 5 * s, 10 * s, dark)
	Draw.fill_rect(image, cx + 2 * s, cy + 4 * s, 5 * s, 10 * s, dark)
	Draw.fill_rect(image, cx - 10 * s, cy - 8 * s + lean, 20 * s, 14 * s, stone)
	Draw.fill_rect(image, cx - 8 * s, cy - 6 * s + lean, 16 * s, 4 * s, light)
	Draw.fill_rect(image, cx - 14 * s, cy - 4 * s + lean + arm_raise, 5 * s, 14 * s, stone)
	Draw.fill_rect(image, cx + 9 * s, cy - 4 * s + lean + arm_raise, 5 * s, 14 * s, stone)
	Draw.fill_circle(image, cx - 12 * s, cy + 10 * s + lean + arm_raise, 4 * s, dark)
	Draw.fill_circle(image, cx + 12 * s, cy + 10 * s + lean + arm_raise, 4 * s, dark)
	Draw.fill_circle(image, cx, cy - 12 * s + lean, 6 * s, stone.lightened(0.1))
	Draw.fill_rect(image, cx - 4 * s, cy - 13 * s + lean, 3 * s, 2 * s, Color(1.0, eye_bright, 0.1))
	Draw.fill_rect(image, cx + 1 * s, cy - 13 * s + lean, 3 * s, 2 * s, Color(1.0, eye_bright, 0.1))
	return ImageTexture.create_from_image(image)
