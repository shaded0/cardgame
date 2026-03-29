extends RefCounted

const Draw = preload("res://scripts/managers/sprite_animator_draw.gd")

static func create_rat_frames() -> SpriteFrames:
	var frames := Draw.new_frames()
	frames.add_animation(&"idle")
	frames.set_animation_speed(&"idle", 4.0)
	frames.set_animation_loop(&"idle", true)
	for i in range(4):
		var twitch: float = sin(i * PI / 2.0) * 1.5
		frames.add_frame(&"idle", _draw_rat_frame(48, twitch, 0.0))

	frames.add_animation(&"run")
	frames.set_animation_speed(&"run", 10.0)
	frames.set_animation_loop(&"run", true)
	for i in range(4):
		var phase: float = float(i) / 4.0 * TAU
		var scurry: float = sin(phase) * 3.0
		var bob: float = absf(sin(phase)) * -2.0
		frames.add_frame(&"run", _draw_rat_frame(48, bob, scurry))

	frames.add_animation(&"attack")
	frames.set_animation_speed(&"attack", 10.0)
	frames.set_animation_loop(&"attack", false)
	for i in range(3):
		var lunge: float = float(i) / 2.0 * -3.0
		frames.add_frame(&"attack", _draw_rat_frame(48, lunge, 0.0))

	return frames

static func create_shaman_frames() -> SpriteFrames:
	var frames := Draw.new_frames()
	frames.add_animation(&"idle")
	frames.set_animation_speed(&"idle", 3.0)
	frames.set_animation_loop(&"idle", true)
	for i in range(4):
		var sway: float = sin(i * PI / 2.0) * 1.5
		frames.add_frame(&"idle", _draw_shaman_frame(48, sway, 0.0))

	frames.add_animation(&"run")
	frames.set_animation_speed(&"run", 6.0)
	frames.set_animation_loop(&"run", true)
	for i in range(4):
		var phase: float = float(i) / 4.0 * TAU
		var waddle: float = sin(phase) * 2.0
		var bob: float = absf(sin(phase)) * -1.5
		frames.add_frame(&"run", _draw_shaman_frame(48, bob, waddle))

	frames.add_animation(&"attack")
	frames.set_animation_speed(&"attack", 6.0)
	frames.set_animation_loop(&"attack", false)
	for i in range(3):
		var reach: float = float(i) / 2.0 * -3.0
		frames.add_frame(&"attack", _draw_shaman_frame(48, reach, 0.0))

	return frames

static func create_beetle_frames() -> SpriteFrames:
	var frames := Draw.new_frames()
	frames.add_animation(&"idle")
	frames.set_animation_speed(&"idle", 2.0)
	frames.set_animation_loop(&"idle", true)
	for i in range(4):
		var pulse: float = sin(i * PI / 2.0) * 0.5
		frames.add_frame(&"idle", _draw_beetle_frame(48, pulse, 0.0))

	frames.add_animation(&"run")
	frames.set_animation_speed(&"run", 5.0)
	frames.set_animation_loop(&"run", true)
	for i in range(4):
		var phase: float = float(i) / 4.0 * TAU
		var leg: float = sin(phase) * 2.5
		var bob: float = absf(sin(phase)) * -1.0
		frames.add_frame(&"run", _draw_beetle_frame(48, bob, leg))

	frames.add_animation(&"attack")
	frames.set_animation_speed(&"attack", 6.0)
	frames.set_animation_loop(&"attack", false)
	for i in range(3):
		var ram: float = float(i) / 2.0 * -4.0
		frames.add_frame(&"attack", _draw_beetle_frame(48, ram, 0.0))

	return frames

static func create_banshee_frames() -> SpriteFrames:
	var frames := Draw.new_frames()
	frames.add_animation(&"idle")
	frames.set_animation_speed(&"idle", 3.0)
	frames.set_animation_loop(&"idle", true)
	for i in range(4):
		var float_y: float = sin(i * PI / 2.0) * 2.0
		var sway: float = sin(i * PI / 2.0 + PI / 3.0) * 1.5
		frames.add_frame(&"idle", _draw_banshee_frame(48, float_y, sway, 0.0))

	frames.add_animation(&"run")
	frames.set_animation_speed(&"run", 7.0)
	frames.set_animation_loop(&"run", true)
	for i in range(4):
		var float_y: float = sin(i * PI / 2.0) * 3.0
		var sway: float = sin(i * PI / 2.0) * 2.5
		frames.add_frame(&"run", _draw_banshee_frame(48, float_y, sway, 0.0))

	frames.add_animation(&"attack")
	frames.set_animation_speed(&"attack", 6.0)
	frames.set_animation_loop(&"attack", false)
	for i in range(3):
		var scream: float = float(i) / 2.0
		frames.add_frame(&"attack", _draw_banshee_frame(48, 0.0, 0.0, scream))

	return frames

static func create_colossus_frames() -> SpriteFrames:
	var frames := Draw.new_frames()
	frames.add_animation(&"idle")
	frames.set_animation_speed(&"idle", 2.0)
	frames.set_animation_loop(&"idle", true)
	for i in range(4):
		var sway: float = sin(i * PI / 2.0) * 1.0
		frames.add_frame(&"idle", _draw_colossus_frame(48, sway, 0.0))

	frames.add_animation(&"run")
	frames.set_animation_speed(&"run", 3.0)
	frames.set_animation_loop(&"run", true)
	for i in range(4):
		var phase: float = float(i) / 4.0 * TAU
		var leg: float = sin(phase) * 2.0
		var bob: float = absf(sin(phase)) * -1.5
		frames.add_frame(&"run", _draw_colossus_frame(48, bob, leg))

	frames.add_animation(&"attack")
	frames.set_animation_speed(&"attack", 4.0)
	frames.set_animation_loop(&"attack", false)
	for i in range(3):
		var slam: float = float(i) / 2.0
		frames.add_frame(&"attack", _draw_colossus_attack_frame(48, slam))

	return frames

static func _draw_rat_frame(size: int, bob: float, scurry: float) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0
	var cy: float = size / 2.0 + bob
	var s: float = size / 48.0
	var body := Color(0.45, 0.35, 0.25)
	var dark := Color(0.3, 0.2, 0.15)
	var belly := Color(0.55, 0.45, 0.35)
	var sore := Color(0.5, 0.6, 0.2)

	Draw.fill_circle(image, size / 2.0, size / 2.0 + 10 * s, 6 * s, Color(0, 0, 0, 0.1))
	Draw.fill_rect(image, cx + 6 * s, cy + 4 * s, 8 * s, 1.5 * s, dark)
	Draw.fill_rect(image, cx + 12 * s, cy + 3 * s + scurry * 0.3, 4 * s, 1.5 * s, dark)
	Draw.fill_circle(image, cx, cy + 2 * s, 8 * s, body)
	Draw.fill_circle(image, cx - 2 * s, cy + 4 * s, 5 * s, belly)
	Draw.fill_circle(image, cx + 3 * s, cy + 1 * s, 2 * s, sore)
	Draw.fill_circle(image, cx - 4 * s, cy + 3 * s, 1.5 * s, sore)
	Draw.fill_rect(image, cx - 5 * s, cy + 7 * s + scurry * 0.5, 2 * s, 4 * s, dark)
	Draw.fill_rect(image, cx + 3 * s, cy + 7 * s - scurry * 0.5, 2 * s, 4 * s, dark)
	Draw.fill_circle(image, cx - 6 * s, cy - 2 * s, 5 * s, body)
	Draw.fill_circle(image, cx - 10 * s, cy - 2 * s, 3 * s, dark)
	Draw.fill_circle(image, cx - 7 * s, cy - 4 * s, 1.5 * s, Color(0.9, 0.2, 0.1))
	Draw.fill_circle(image, cx - 4 * s, cy - 6 * s, 2.5 * s, body.lightened(0.2))
	Draw.fill_circle(image, cx - 2 * s, cy - 6 * s, 2.5 * s, body.lightened(0.2))
	return ImageTexture.create_from_image(image)

static func _draw_shaman_frame(size: int, bob: float, waddle: float) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0 + waddle
	var cy: float = size / 2.0 + bob
	var s: float = size / 48.0
	var cap := Color(0.7, 0.15, 0.1)
	var spots := Color(1.0, 0.9, 0.7)
	var stem := Color(0.85, 0.8, 0.7)
	var dark := Color(0.5, 0.4, 0.35)

	Draw.fill_circle(image, size / 2.0, size / 2.0 + 12 * s, 7 * s, Color(0, 0, 0, 0.1))
	Draw.fill_rect(image, cx - 4 * s, cy + 6 * s, 2.5 * s, 6 * s, dark)
	Draw.fill_rect(image, cx + 1.5 * s, cy + 6 * s, 2.5 * s, 6 * s, dark)
	Draw.fill_circle(image, cx, cy + 2 * s, 7 * s, stem)
	Draw.fill_circle(image, cx, cy + 4 * s, 5 * s, stem.darkened(0.1))
	Draw.fill_rect(image, cx + 8 * s, cy - 12 * s, 2 * s, 18 * s, Color(0.4, 0.3, 0.2))
	Draw.fill_circle(image, cx + 9 * s, cy - 13 * s, 3 * s, Color(0.3, 0.8, 0.2, 0.8))
	Draw.fill_circle(image, cx + 9 * s, cy - 13 * s, 1.5 * s, Color(0.5, 1.0, 0.3, 0.6))
	Draw.fill_circle(image, cx, cy - 8 * s, 10 * s, cap)
	Draw.fill_circle(image, cx, cy - 10 * s, 8 * s, cap.lightened(0.15))
	Draw.fill_circle(image, cx - 4 * s, cy - 12 * s, 2 * s, spots)
	Draw.fill_circle(image, cx + 3 * s, cy - 10 * s, 2.5 * s, spots)
	Draw.fill_circle(image, cx + 6 * s, cy - 7 * s, 1.5 * s, spots)
	Draw.fill_circle(image, cx - 7 * s, cy - 7 * s, 1.5 * s, spots)
	Draw.fill_circle(image, cx - 3 * s, cy - 3 * s, 2 * s, Color(0.1, 0.1, 0.1))
	Draw.fill_circle(image, cx + 3 * s, cy - 3 * s, 2 * s, Color(0.1, 0.1, 0.1))
	Draw.fill_circle(image, cx - 3 * s, cy - 3.5 * s, 1 * s, Color(0.3, 0.9, 0.2))
	Draw.fill_circle(image, cx + 3 * s, cy - 3.5 * s, 1 * s, Color(0.3, 0.9, 0.2))
	return ImageTexture.create_from_image(image)

static func _draw_beetle_frame(size: int, bob: float, leg_offset: float) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0
	var cy: float = size / 2.0 + bob
	var s: float = size / 48.0
	var shell := Color(0.4, 0.42, 0.45)
	var light := Color(0.55, 0.58, 0.62)
	var dark := Color(0.25, 0.22, 0.2)
	var spike := Color(0.7, 0.5, 0.3)

	Draw.fill_circle(image, size / 2.0, size / 2.0 + 10 * s, 9 * s, Color(0, 0, 0, 0.12))
	Draw.fill_rect(image, cx - 10 * s, cy + 2 * s + leg_offset, 3 * s, 6 * s, dark)
	Draw.fill_rect(image, cx + 7 * s, cy + 2 * s - leg_offset, 3 * s, 6 * s, dark)
	Draw.fill_rect(image, cx - 12 * s, cy + 0 * s - leg_offset * 0.5, 3 * s, 5 * s, dark)
	Draw.fill_rect(image, cx + 9 * s, cy + 0 * s + leg_offset * 0.5, 3 * s, 5 * s, dark)
	Draw.fill_rect(image, cx - 8 * s, cy + 4 * s - leg_offset * 0.3, 2 * s, 5 * s, dark)
	Draw.fill_rect(image, cx + 6 * s, cy + 4 * s + leg_offset * 0.3, 2 * s, 5 * s, dark)
	Draw.fill_circle(image, cx, cy, 10 * s, shell)
	Draw.fill_circle(image, cx, cy - 2 * s, 9 * s, light)
	Draw.fill_rect(image, cx - 1 * s, cy - 8 * s, 2 * s, 14 * s, dark)
	Draw.fill_circle(image, cx - 3 * s, cy - 4 * s, 3 * s, light.lightened(0.2))
	Draw.fill_rect(image, cx - 6 * s, cy - 8 * s, 2 * s, 3 * s, spike)
	Draw.fill_rect(image, cx + 4 * s, cy - 8 * s, 2 * s, 3 * s, spike)
	Draw.fill_rect(image, cx, cy - 10 * s, 2 * s, 3 * s, spike)
	Draw.fill_circle(image, cx, cy - 9 * s, 4 * s, dark)
	Draw.fill_rect(image, cx - 4 * s, cy - 12 * s, 2 * s, 4 * s, spike)
	Draw.fill_rect(image, cx + 2 * s, cy - 12 * s, 2 * s, 4 * s, spike)
	Draw.fill_circle(image, cx - 2 * s, cy - 10 * s, 1.5 * s, Color(0.9, 0.5, 0.1))
	Draw.fill_circle(image, cx + 2 * s, cy - 10 * s, 1.5 * s, Color(0.9, 0.5, 0.1))
	return ImageTexture.create_from_image(image)

static func _draw_banshee_frame(size: int, float_y: float, sway: float, scream: float) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0 + sway
	var cy: float = size / 2.0 + float_y
	var s: float = size / 48.0
	var body := Color(0.75, 0.8, 0.85, 0.7)
	var hair := Color(0.15, 0.1, 0.2, 0.8)
	var glow := Color(0.4, 0.8, 0.9, 0.5)
	var wisp := Color(0.6, 0.7, 0.8, 0.3)
	var arm_spread: float = 8 * s + scream * 4 * s
	var eye_size: float = 2 * s + scream * 1 * s

	Draw.fill_circle(image, cx, cy + 10 * s, 5 * s, wisp)
	Draw.fill_circle(image, cx - 2 * s, cy + 13 * s, 3 * s, Color(wisp.r, wisp.g, wisp.b, 0.15))
	Draw.fill_circle(image, cx + 3 * s, cy + 14 * s, 2 * s, Color(wisp.r, wisp.g, wisp.b, 0.1))
	Draw.fill_circle(image, cx, cy + 2 * s, 7 * s, body)
	Draw.fill_circle(image, cx, cy - 2 * s, 6 * s, body)
	Draw.fill_circle(image, cx, cy - 10 * s, 8 * s, hair)
	Draw.fill_rect(image, cx - 8 * s, cy - 8 * s, 4 * s, 12 * s, hair)
	Draw.fill_rect(image, cx + 4 * s, cy - 8 * s, 4 * s, 12 * s, hair)
	Draw.fill_circle(image, cx, cy - 7 * s, 5 * s, Color(0.9, 0.85, 0.9, 0.9))
	Draw.fill_rect(image, cx - arm_spread - 3 * s, cy - 2 * s, 4 * s, 2 * s, body)
	Draw.fill_rect(image, cx + arm_spread - 1 * s, cy - 2 * s, 4 * s, 2 * s, body)
	Draw.fill_circle(image, cx - 3 * s, cy - 8 * s, eye_size, glow)
	Draw.fill_circle(image, cx + 3 * s, cy - 8 * s, eye_size, glow)
	Draw.fill_circle(image, cx - 3 * s, cy - 8 * s, eye_size * 0.5, Color(0.8, 1.0, 1.0, 0.8))
	Draw.fill_circle(image, cx + 3 * s, cy - 8 * s, eye_size * 0.5, Color(0.8, 1.0, 1.0, 0.8))
	if scream > 0.3:
		var mouth_size: float = 2 * s + scream * 2 * s
		Draw.fill_circle(image, cx, cy - 4 * s, mouth_size, Color(0.1, 0.05, 0.15, 0.9))
		Draw.fill_circle(image, cx, cy - 4 * s, mouth_size + 4 * s, Color(glow.r, glow.g, glow.b, 0.2))
	return ImageTexture.create_from_image(image)

static func _draw_colossus_frame(size: int, bob: float, leg_offset: float) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0
	var cy: float = size / 2.0
	var s: float = size / 48.0
	var bone := Color(0.8, 0.75, 0.65)
	var dark := Color(0.5, 0.4, 0.35)
	var glow := Color(0.4, 0.9, 0.3, 0.6)
	var socket := Color(0.1, 0.05, 0.0)

	Draw.fill_circle(image, cx, cy + 14 * s, 11 * s, Color(0, 0, 0, 0.15))
	Draw.fill_rect(image, cx - 7 * s, cy + 3 * s + leg_offset, 5 * s, 11 * s, bone)
	Draw.fill_rect(image, cx + 2 * s, cy + 3 * s - leg_offset, 5 * s, 11 * s, bone)
	Draw.fill_rect(image, cx - 6 * s, cy + 6 * s + leg_offset, 3 * s, 2 * s, dark)
	Draw.fill_rect(image, cx + 3 * s, cy + 6 * s - leg_offset, 3 * s, 2 * s, dark)
	Draw.fill_rect(image, cx - 9 * s, cy - 6 * s + bob, 18 * s, 10 * s, bone)
	Draw.fill_rect(image, cx - 8 * s, cy - 4 * s + bob, 16 * s, 1 * s, dark)
	Draw.fill_rect(image, cx - 7 * s, cy - 1 * s + bob, 14 * s, 1 * s, dark)
	Draw.fill_rect(image, cx - 6 * s, cy + 2 * s + bob, 12 * s, 1 * s, dark)
	Draw.fill_rect(image, cx - 1 * s, cy - 6 * s + bob, 2 * s, 10 * s, dark)
	Draw.fill_circle(image, cx, cy - 2 * s + bob, 4 * s, glow)
	Draw.fill_rect(image, cx - 13 * s, cy - 4 * s + bob, 5 * s, 12 * s, bone)
	Draw.fill_rect(image, cx + 8 * s, cy - 4 * s + bob, 5 * s, 12 * s, bone)
	Draw.fill_rect(image, cx - 11 * s, cy - 2 * s + bob, 3 * s, 6 * s, bone.darkened(0.15))
	Draw.fill_rect(image, cx + 8 * s, cy - 2 * s + bob, 3 * s, 6 * s, bone.darkened(0.15))
	Draw.fill_circle(image, cx - 11 * s, cy + 8 * s + bob, 3.5 * s, dark)
	Draw.fill_circle(image, cx + 11 * s, cy + 8 * s + bob, 3.5 * s, dark)
	Draw.fill_circle(image, cx, cy - 11 * s + bob, 6 * s, bone)
	Draw.fill_circle(image, cx - 5 * s, cy - 9 * s + bob, 4 * s, bone.darkened(0.1))
	Draw.fill_circle(image, cx + 5 * s, cy - 9 * s + bob, 4 * s, bone.darkened(0.1))
	Draw.fill_circle(image, cx - 2 * s, cy - 12 * s + bob, 2 * s, socket)
	Draw.fill_circle(image, cx + 2 * s, cy - 12 * s + bob, 2 * s, socket)
	Draw.fill_circle(image, cx - 2 * s, cy - 12 * s + bob, 1 * s, glow)
	Draw.fill_circle(image, cx + 2 * s, cy - 12 * s + bob, 1 * s, glow)
	Draw.fill_circle(image, cx - 6 * s, cy - 10 * s + bob, 1 * s, glow)
	Draw.fill_circle(image, cx + 6 * s, cy - 10 * s + bob, 1 * s, glow)
	return ImageTexture.create_from_image(image)

static func _draw_colossus_attack_frame(size: int, slam: float) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0
	var cy: float = size / 2.0
	var s: float = size / 48.0
	var bone := Color(0.8, 0.75, 0.65)
	var dark := Color(0.5, 0.4, 0.35)
	var glow := Color(0.4, 0.9, 0.3, 0.6)
	var lean: float = -2.0 * slam
	var arm_raise: float = -8.0 * (1.0 - slam)
	var eye_bright: float = 0.4 + slam * 0.5

	Draw.fill_circle(image, cx, cy + 14 * s, 11 * s, Color(0, 0, 0, 0.15))
	Draw.fill_rect(image, cx - 7 * s, cy + 3 * s, 5 * s, 11 * s, bone)
	Draw.fill_rect(image, cx + 2 * s, cy + 3 * s, 5 * s, 11 * s, bone)
	Draw.fill_rect(image, cx - 9 * s, cy - 6 * s + lean, 18 * s, 10 * s, bone)
	Draw.fill_rect(image, cx - 1 * s, cy - 6 * s + lean, 2 * s, 10 * s, dark)
	Draw.fill_circle(image, cx, cy - 2 * s + lean, 4 * s, Color(glow.r, glow.g, glow.b, 0.6 + slam * 0.3))
	Draw.fill_rect(image, cx - 13 * s, cy - 4 * s + lean + arm_raise, 5 * s, 12 * s, bone)
	Draw.fill_rect(image, cx + 8 * s, cy - 4 * s + lean + arm_raise, 5 * s, 12 * s, bone)
	Draw.fill_circle(image, cx - 11 * s, cy + 8 * s + lean + arm_raise, 3.5 * s, dark)
	Draw.fill_circle(image, cx + 11 * s, cy + 8 * s + lean + arm_raise, 3.5 * s, dark)
	Draw.fill_circle(image, cx, cy - 11 * s + lean, 6 * s, bone)
	Draw.fill_circle(image, cx - 5 * s, cy - 9 * s + lean, 4 * s, bone.darkened(0.1))
	Draw.fill_circle(image, cx + 5 * s, cy - 9 * s + lean, 4 * s, bone.darkened(0.1))
	Draw.fill_circle(image, cx - 2 * s, cy - 12 * s + lean, 1.5 * s, Color(eye_bright, 1.0, eye_bright * 0.8, 0.9))
	Draw.fill_circle(image, cx + 2 * s, cy - 12 * s + lean, 1.5 * s, Color(eye_bright, 1.0, eye_bright * 0.8, 0.9))
	return ImageTexture.create_from_image(image)
