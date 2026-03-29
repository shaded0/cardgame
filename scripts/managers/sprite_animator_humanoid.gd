extends RefCounted

const Draw = preload("res://scripts/managers/sprite_animator_draw.gd")

static func create_humanoid_frames(body_color: Color, detail_color: Color, weapon: String = "sword") -> SpriteFrames:
	var frames := Draw.new_frames()

	frames.add_animation(&"idle")
	frames.set_animation_speed(&"idle", 4.0)
	frames.set_animation_loop(&"idle", true)
	for i in range(4):
		var bob: float = sin(i * PI / 2.0) * 1.5
		frames.add_frame(&"idle", _draw_humanoid_frame(48, body_color, detail_color, weapon, bob, 0.0, 0.0))

	frames.add_animation(&"walk")
	frames.set_animation_speed(&"walk", 6.0)
	frames.set_animation_loop(&"walk", true)
	for i in range(6):
		var phase: float = float(i) / 6.0 * TAU
		var leg_offset: float = sin(phase) * 2.0
		var arm_offset: float = sin(phase + PI) * 1.5
		var bob: float = absf(sin(phase)) * -1.0
		frames.add_frame(&"walk", _draw_humanoid_frame(48, body_color, detail_color, weapon, bob, leg_offset, arm_offset))

	frames.add_animation(&"run")
	frames.set_animation_speed(&"run", 10.0)
	frames.set_animation_loop(&"run", true)
	for i in range(6):
		var phase: float = float(i) / 6.0 * TAU
		var leg_offset: float = sin(phase) * 4.0
		var arm_offset: float = sin(phase + PI) * 3.0
		var bob: float = absf(sin(phase)) * -2.0
		frames.add_frame(&"run", _draw_humanoid_frame(48, body_color, detail_color, weapon, bob, leg_offset, arm_offset))

	frames.add_animation(&"attack")
	frames.set_animation_speed(&"attack", 8.0)
	frames.set_animation_loop(&"attack", false)
	for i in range(4):
		var swing: float = float(i) / 3.0
		frames.add_frame(&"attack", _draw_humanoid_attack_frame(48, body_color, detail_color, weapon, swing))

	frames.add_animation(&"dodge")
	frames.set_animation_speed(&"dodge", 6.0)
	frames.set_animation_loop(&"dodge", false)
	for i in range(3):
		var squash: float = 0.7 + float(i) * 0.15
		frames.add_frame(&"dodge", _draw_humanoid_dodge_frame(48, body_color, detail_color, squash))

	return frames

static func _draw_humanoid_frame(size: int, body_color: Color, detail_color: Color, weapon: String, bob: float, leg_offset: float, arm_offset: float) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0
	var cy: float = size / 2.0
	var s: float = size / 48.0

	var skin := Color(0.9, 0.75, 0.6, 1.0)
	var dark := body_color.darkened(0.3)
	var light := body_color.lightened(0.2)
	var outline := body_color.darkened(0.5)

	Draw.fill_rect(image, cx - 5 * s, cy + 6 * s + leg_offset, 4 * s, 10 * s, dark)
	Draw.fill_rect(image, cx + 1 * s, cy + 6 * s - leg_offset, 4 * s, 10 * s, dark)
	Draw.fill_rect(image, cx - 5 * s, cy + 13 * s + leg_offset, 4 * s, 3 * s, outline)
	Draw.fill_rect(image, cx + 1 * s, cy + 13 * s - leg_offset, 4 * s, 3 * s, outline)
	Draw.fill_rect(image, cx - 6 * s, cy - 4 * s + bob, 12 * s, 12 * s, body_color)
	Draw.fill_rect(image, cx - 4 * s, cy - 3 * s + bob, 8 * s, 4 * s, light)
	Draw.fill_rect(image, cx - 6 * s, cy + 5 * s + bob, 12 * s, 3 * s, outline)
	Draw.fill_rect(image, cx - 10 * s, cy - 2 * s + bob - arm_offset, 4 * s, 10 * s, body_color)
	Draw.fill_circle(image, cx - 8 * s, cy + 8 * s + bob - arm_offset, 2.5 * s, skin)
	Draw.fill_rect(image, cx + 6 * s, cy - 2 * s + bob + arm_offset, 4 * s, 10 * s, body_color)
	Draw.fill_circle(image, cx + 8 * s, cy + 8 * s + bob + arm_offset, 2.5 * s, skin)
	Draw.fill_circle(image, cx - 8 * s, cy - 2 * s + bob, 3.5 * s, detail_color)
	Draw.fill_circle(image, cx + 8 * s, cy - 2 * s + bob, 3.5 * s, detail_color)
	Draw.fill_rect(image, cx - 2 * s, cy - 7 * s + bob, 4 * s, 4 * s, skin)
	Draw.fill_circle(image, cx, cy - 10 * s + bob, 6 * s, skin)
	Draw.fill_circle(image, cx, cy - 12 * s + bob, 5 * s, detail_color)
	Draw.fill_rect(image, cx - 3 * s, cy - 11 * s + bob, 2 * s, 2 * s, Color(0.15, 0.15, 0.2))
	Draw.fill_rect(image, cx + 1 * s, cy - 11 * s + bob, 2 * s, 2 * s, Color(0.15, 0.15, 0.2))
	_draw_weapon(image, cx, cy, s, bob, weapon)
	return ImageTexture.create_from_image(image)

static func _draw_humanoid_attack_frame(size: int, body_color: Color, detail_color: Color, weapon: String, swing: float) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0
	var cy: float = size / 2.0
	var s: float = size / 48.0

	var skin := Color(0.9, 0.75, 0.6, 1.0)
	var dark := body_color.darkened(0.3)
	var light := body_color.lightened(0.2)
	var outline := body_color.darkened(0.5)
	var lean: float = -2.0 * swing
	var arm_extend: float = -8.0 * swing

	Draw.fill_rect(image, cx - 5 * s, cy + 6 * s, 4 * s, 10 * s, dark)
	Draw.fill_rect(image, cx + 1 * s, cy + 6 * s, 4 * s, 10 * s, dark)
	Draw.fill_rect(image, cx - 5 * s, cy + 13 * s, 4 * s, 3 * s, outline)
	Draw.fill_rect(image, cx + 1 * s, cy + 13 * s, 4 * s, 3 * s, outline)
	Draw.fill_rect(image, cx - 6 * s, cy - 4 * s + lean, 12 * s, 12 * s, body_color)
	Draw.fill_rect(image, cx - 4 * s, cy - 3 * s + lean, 8 * s, 4 * s, light)
	Draw.fill_rect(image, cx - 6 * s, cy + 5 * s + lean, 12 * s, 3 * s, outline)
	Draw.fill_rect(image, cx - 10 * s, cy - 2 * s + lean, 4 * s, 10 * s, body_color)
	Draw.fill_circle(image, cx - 8 * s, cy + 8 * s + lean, 2.5 * s, skin)
	Draw.fill_rect(image, cx + 6 * s, cy - 2 * s + lean + arm_extend, 4 * s, 10 * s, body_color)
	Draw.fill_circle(image, cx + 8 * s, cy + 8 * s + lean + arm_extend, 2.5 * s, skin)
	Draw.fill_circle(image, cx - 8 * s, cy - 2 * s + lean, 3.5 * s, detail_color)
	Draw.fill_circle(image, cx + 8 * s, cy - 2 * s + lean, 3.5 * s, detail_color)
	Draw.fill_rect(image, cx - 2 * s, cy - 7 * s + lean, 4 * s, 4 * s, skin)
	Draw.fill_circle(image, cx, cy - 10 * s + lean, 6 * s, skin)
	Draw.fill_circle(image, cx, cy - 12 * s + lean, 5 * s, detail_color)
	Draw.fill_rect(image, cx - 3 * s, cy - 11 * s + lean, 2 * s, 2 * s, Color(0.15, 0.15, 0.2))
	Draw.fill_rect(image, cx + 1 * s, cy - 11 * s + lean, 2 * s, 2 * s, Color(0.15, 0.15, 0.2))
	_draw_weapon_attack(image, cx, cy, s, lean, arm_extend, weapon, swing)
	return ImageTexture.create_from_image(image)

static func _draw_humanoid_dodge_frame(size: int, body_color: Color, detail_color: Color, squash: float) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0
	var cy: float = size / 2.0
	var s: float = size / 48.0

	var skin := Color(0.9, 0.75, 0.6, 1.0)
	var dark := body_color.darkened(0.3)
	var light := body_color.lightened(0.2)
	var shrink: float = (1.0 - squash) * 6.0

	Draw.fill_rect(image, cx - 5 * s, cy + 4 * s + shrink, 4 * s, 8 * s, dark)
	Draw.fill_rect(image, cx + 1 * s, cy + 4 * s + shrink, 4 * s, 8 * s, dark)
	Draw.fill_rect(image, cx - 7 * s, cy - 2 * s + shrink, 14 * s, 10 * s, body_color)
	Draw.fill_rect(image, cx - 5 * s, cy - 1 * s + shrink, 10 * s, 3 * s, light)
	Draw.fill_rect(image, cx - 9 * s, cy + shrink, 3 * s, 8 * s, body_color)
	Draw.fill_rect(image, cx + 6 * s, cy + shrink, 3 * s, 8 * s, body_color)
	Draw.fill_circle(image, cx, cy - 5 * s + shrink, 5 * s, skin)
	Draw.fill_circle(image, cx, cy - 7 * s + shrink, 4 * s, detail_color)
	Draw.fill_rect(image, cx - 2 * s, cy - 6 * s + shrink, 2 * s, 1 * s, Color(0.15, 0.15, 0.2))
	Draw.fill_rect(image, cx + 1 * s, cy - 6 * s + shrink, 2 * s, 1 * s, Color(0.15, 0.15, 0.2))
	Draw.fill_rect(image, cx - 2 * s, cy + 14 * s, 1 * s, 5 * s, Color(1, 1, 1, 0.2))
	Draw.fill_rect(image, cx + 2 * s, cy + 15 * s, 1 * s, 4 * s, Color(1, 1, 1, 0.15))
	return ImageTexture.create_from_image(image)

static func _draw_weapon(img: Image, cx: float, cy: float, s: float, bob: float, weapon: String) -> void:
	match weapon:
		"sword":
			var blade := Color(0.8, 0.85, 0.9, 1.0)
			var hilt := Color(0.6, 0.5, 0.2, 1.0)
			Draw.fill_rect(img, cx + 10 * s, cy - 14 * s + bob, 3 * s, 12 * s, blade)
			Draw.fill_rect(img, cx + 10 * s, cy - 15 * s + bob, 3 * s, 2 * s, blade.lightened(0.2))
			Draw.fill_rect(img, cx + 9 * s, cy - 2 * s + bob, 5 * s, 2 * s, hilt)
		"daggers":
			var blade := Color(0.75, 0.8, 0.75, 1.0)
			Draw.fill_rect(img, cx - 9 * s, cy - 6 * s + bob, 2 * s, 8 * s, blade)
			Draw.fill_rect(img, cx + 9 * s, cy - 6 * s + bob, 2 * s, 8 * s, blade)
			Draw.fill_rect(img, cx - 9 * s, cy - 7 * s + bob, 2 * s, 2 * s, blade.lightened(0.2))
			Draw.fill_rect(img, cx + 9 * s, cy - 7 * s + bob, 2 * s, 2 * s, blade.lightened(0.2))
		"staff":
			var wood := Color(0.5, 0.35, 0.2, 1.0)
			var orb := Color(0.6, 0.3, 1.0, 0.9)
			Draw.fill_rect(img, cx + 10 * s, cy - 16 * s + bob, 2 * s, 28 * s, wood)
			Draw.fill_circle(img, cx + 11 * s, cy - 17 * s + bob, 3 * s, orb)
			Draw.fill_circle(img, cx + 11 * s, cy - 17 * s + bob, 1.5 * s, orb.lightened(0.3))

static func _draw_weapon_attack(img: Image, cx: float, cy: float, s: float, lean: float, arm_ext: float, weapon: String, swing: float) -> void:
	match weapon:
		"sword":
			var blade := Color(0.8, 0.85, 0.9, 1.0)
			var blade_y: float = cy - 14 * s + lean + arm_ext - swing * 8.0
			Draw.fill_rect(img, cx + 10 * s, blade_y, 3 * s, 14 * s, blade)
			Draw.fill_rect(img, cx + 10 * s, blade_y - 2 * s, 3 * s, 2 * s, Color(1, 1, 1, 0.8))
		"daggers":
			var blade := Color(0.75, 0.8, 0.75, 1.0)
			var stab: float = swing * 6.0
			Draw.fill_rect(img, cx - 9 * s, cy - 6 * s + lean - stab, 2 * s, 10 * s, blade)
			Draw.fill_rect(img, cx + 9 * s, cy - 8 * s + lean + arm_ext, 2 * s, 10 * s, blade)
		"staff":
			var wood := Color(0.5, 0.35, 0.2, 1.0)
			var orb := Color(0.6, 0.3, 1.0, 0.9)
			Draw.fill_rect(img, cx + 10 * s, cy - 18 * s + lean + arm_ext, 2 * s, 28 * s, wood)
			var orb_glow: float = 1.0 + swing * 0.5
			Draw.fill_circle(img, cx + 11 * s, cy - 19 * s + lean + arm_ext, 3 * s * orb_glow, orb)
			Draw.fill_circle(img, cx + 11 * s, cy - 19 * s + lean + arm_ext, 1.5 * s * orb_glow, Color(1, 1, 1, 0.5))
