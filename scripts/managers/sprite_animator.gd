class_name SpriteAnimator
extends RefCounted

## Generates SpriteFrames with multiple animation states for humanoid and enemy characters.
## This keeps art data generated at runtime during prototyping.

# ─── drawing helpers (shared by all generators) ───
## Low-level shape primitives for building textures without imported sprites.

static func _fill_circle(img: Image, cx: float, cy: float, r: float, col: Color) -> void:
	# Scan a local pixel window and paint all points inside a radius.
	for dy in range(int(-r) - 1, int(r) + 2):
		for dx in range(int(-r) - 1, int(r) + 2):
			var px: int = int(cx) + dx
			var py: int = int(cy) + dy
			if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
				if dx * dx + dy * dy <= r * r:
					img.set_pixel(px, py, col)

static func _fill_rect(img: Image, rx: float, ry: float, rw: float, rh: float, col: Color) -> void:
	# Fill a rectangular area by iterating image coordinates.
	for dy in range(int(rh)):
		for dx in range(int(rw)):
			var px: int = int(rx) + dx
			var py: int = int(ry) + dy
			if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
				img.set_pixel(px, py, col)

# ─── humanoid sprite frames ───

static func create_humanoid_frames(body_color: Color, detail_color: Color, weapon: String = "sword") -> SpriteFrames:
	# Public factory for player-like characters. Returns a full SpriteFrames object.
	var frames := SpriteFrames.new()

	# Remove the default animation
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

	# idle: 4 frames, gentle bob
	frames.add_animation(&"idle")
	frames.set_animation_speed(&"idle", 4.0)
	frames.set_animation_loop(&"idle", true)
	for i in range(4):
		var bob: float = sin(i * PI / 2.0) * 1.5
		var tex: Texture2D = _draw_humanoid_frame(48, body_color, detail_color, weapon, bob, 0.0, 0.0)
		frames.add_frame(&"idle", tex)

	# walk: 6 frames, gentle stride (slower, smaller motion than run)
	frames.add_animation(&"walk")
	frames.set_animation_speed(&"walk", 6.0)
	frames.set_animation_loop(&"walk", true)
	for i in range(6):
		var phase: float = float(i) / 6.0 * TAU
		var leg_offset: float = sin(phase) * 2.0
		var arm_offset: float = sin(phase + PI) * 1.5
		var bob: float = absf(sin(phase)) * -1.0
		var tex: Texture2D = _draw_humanoid_frame(48, body_color, detail_color, weapon, bob, leg_offset, arm_offset)
		frames.add_frame(&"walk", tex)

	# run: 6 frames, leg stride + arm pump
	frames.add_animation(&"run")
	frames.set_animation_speed(&"run", 10.0)
	frames.set_animation_loop(&"run", true)
	for i in range(6):
		var phase: float = float(i) / 6.0 * TAU
		var leg_offset: float = sin(phase) * 4.0
		var arm_offset: float = sin(phase + PI) * 3.0
		var bob: float = absf(sin(phase)) * -2.0
		var tex: Texture2D = _draw_humanoid_frame(48, body_color, detail_color, weapon, bob, leg_offset, arm_offset)
		frames.add_frame(&"run", tex)

	# attack: 4 frames, weapon swing
	frames.add_animation(&"attack")
	frames.set_animation_speed(&"attack", 8.0)
	frames.set_animation_loop(&"attack", false)
	for i in range(4):
		var swing: float = float(i) / 3.0  # 0 to 1
		var tex: Texture2D = _draw_humanoid_attack_frame(48, body_color, detail_color, weapon, swing)
		frames.add_frame(&"attack", tex)

	# dodge: 3 frames, tucked in
	frames.add_animation(&"dodge")
	frames.set_animation_speed(&"dodge", 6.0)
	frames.set_animation_loop(&"dodge", false)
	for i in range(3):
		var squash: float = 0.7 + float(i) * 0.15
		var tex: Texture2D = _draw_humanoid_dodge_frame(48, body_color, detail_color, squash)
		frames.add_frame(&"dodge", tex)

	return frames

static func _draw_humanoid_frame(size: int, body_color: Color, detail_color: Color, weapon: String, bob: float, leg_offset: float, arm_offset: float) -> Texture2D:
	# Builds one animation frame for idle/run by composing simple body/limb shapes.
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0
	var cy: float = size / 2.0
	var s: float = size / 48.0

	var skin := Color(0.9, 0.75, 0.6, 1.0)
	var dark := body_color.darkened(0.3)
	var light := body_color.lightened(0.2)
	var outline := body_color.darkened(0.5)

	# Legs with stride animation
	_fill_rect(image, cx - 5 * s, cy + 6 * s + leg_offset, 4 * s, 10 * s, dark)
	_fill_rect(image, cx + 1 * s, cy + 6 * s - leg_offset, 4 * s, 10 * s, dark)
	_fill_rect(image, cx - 5 * s, cy + 13 * s + leg_offset, 4 * s, 3 * s, outline)
	_fill_rect(image, cx + 1 * s, cy + 13 * s - leg_offset, 4 * s, 3 * s, outline)

	# Body with bob
	_fill_rect(image, cx - 6 * s, cy - 4 * s + bob, 12 * s, 12 * s, body_color)
	_fill_rect(image, cx - 4 * s, cy - 3 * s + bob, 8 * s, 4 * s, light)
	_fill_rect(image, cx - 6 * s, cy + 5 * s + bob, 12 * s, 3 * s, outline)

	# Arms with pump animation
	_fill_rect(image, cx - 10 * s, cy - 2 * s + bob - arm_offset, 4 * s, 10 * s, body_color)
	_fill_circle(image, cx - 8 * s, cy + 8 * s + bob - arm_offset, 2.5 * s, skin)
	_fill_rect(image, cx + 6 * s, cy - 2 * s + bob + arm_offset, 4 * s, 10 * s, body_color)
	_fill_circle(image, cx + 8 * s, cy + 8 * s + bob + arm_offset, 2.5 * s, skin)

	# Shoulders
	_fill_circle(image, cx - 8 * s, cy - 2 * s + bob, 3.5 * s, detail_color)
	_fill_circle(image, cx + 8 * s, cy - 2 * s + bob, 3.5 * s, detail_color)

	# Head
	_fill_rect(image, cx - 2 * s, cy - 7 * s + bob, 4 * s, 4 * s, skin)
	_fill_circle(image, cx, cy - 10 * s + bob, 6 * s, skin)
	_fill_circle(image, cx, cy - 12 * s + bob, 5 * s, detail_color)
	_fill_rect(image, cx - 3 * s, cy - 11 * s + bob, 2 * s, 2 * s, Color(0.15, 0.15, 0.2))
	_fill_rect(image, cx + 1 * s, cy - 11 * s + bob, 2 * s, 2 * s, Color(0.15, 0.15, 0.2))

	# Weapon
	_draw_weapon(image, cx, cy, s, bob, weapon)

	return ImageTexture.create_from_image(image)

static func _draw_humanoid_attack_frame(size: int, body_color: Color, detail_color: Color, weapon: String, swing: float) -> Texture2D:
	# Build a single attack-frame where weapon and torso lean based on `swing`.
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0
	var cy: float = size / 2.0
	var s: float = size / 48.0

	var skin := Color(0.9, 0.75, 0.6, 1.0)
	var dark := body_color.darkened(0.3)
	var light := body_color.lightened(0.2)
	var outline := body_color.darkened(0.5)

	# Legs planted
	_fill_rect(image, cx - 5 * s, cy + 6 * s, 4 * s, 10 * s, dark)
	_fill_rect(image, cx + 1 * s, cy + 6 * s, 4 * s, 10 * s, dark)
	_fill_rect(image, cx - 5 * s, cy + 13 * s, 4 * s, 3 * s, outline)
	_fill_rect(image, cx + 1 * s, cy + 13 * s, 4 * s, 3 * s, outline)

	# Body leaning forward
	var lean: float = -2.0 * swing
	_fill_rect(image, cx - 6 * s, cy - 4 * s + lean, 12 * s, 12 * s, body_color)
	_fill_rect(image, cx - 4 * s, cy - 3 * s + lean, 8 * s, 4 * s, light)
	_fill_rect(image, cx - 6 * s, cy + 5 * s + lean, 12 * s, 3 * s, outline)

	# Left arm back
	_fill_rect(image, cx - 10 * s, cy - 2 * s + lean, 4 * s, 10 * s, body_color)
	_fill_circle(image, cx - 8 * s, cy + 8 * s + lean, 2.5 * s, skin)

	# Right arm — thrust forward based on swing progress
	var arm_extend: float = -8.0 * swing
	_fill_rect(image, cx + 6 * s, cy - 2 * s + lean + arm_extend, 4 * s, 10 * s, body_color)
	_fill_circle(image, cx + 8 * s, cy + 8 * s + lean + arm_extend, 2.5 * s, skin)

	# Shoulders
	_fill_circle(image, cx - 8 * s, cy - 2 * s + lean, 3.5 * s, detail_color)
	_fill_circle(image, cx + 8 * s, cy - 2 * s + lean, 3.5 * s, detail_color)

	# Head
	_fill_rect(image, cx - 2 * s, cy - 7 * s + lean, 4 * s, 4 * s, skin)
	_fill_circle(image, cx, cy - 10 * s + lean, 6 * s, skin)
	_fill_circle(image, cx, cy - 12 * s + lean, 5 * s, detail_color)
	_fill_rect(image, cx - 3 * s, cy - 11 * s + lean, 2 * s, 2 * s, Color(0.15, 0.15, 0.2))
	_fill_rect(image, cx + 1 * s, cy - 11 * s + lean, 2 * s, 2 * s, Color(0.15, 0.15, 0.2))

	# Weapon swinging forward
	_draw_weapon_attack(image, cx, cy, s, lean, arm_extend, weapon, swing)

	return ImageTexture.create_from_image(image)

static func _draw_humanoid_dodge_frame(size: int, body_color: Color, detail_color: Color, squash: float) -> Texture2D:
	# Build one dodge-frame with compacted posture and motion lines.
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0
	var cy: float = size / 2.0
	var s: float = size / 48.0

	var skin := Color(0.9, 0.75, 0.6, 1.0)
	var dark := body_color.darkened(0.3)
	var outline := body_color.darkened(0.5)
	var light := body_color.lightened(0.2)

	# Compact crouched pose
	var shrink: float = (1.0 - squash) * 6.0
	_fill_rect(image, cx - 5 * s, cy + 4 * s + shrink, 4 * s, 8 * s, dark)
	_fill_rect(image, cx + 1 * s, cy + 4 * s + shrink, 4 * s, 8 * s, dark)

	# Body squashed
	_fill_rect(image, cx - 7 * s, cy - 2 * s + shrink, 14 * s, 10 * s, body_color)
	_fill_rect(image, cx - 5 * s, cy - 1 * s + shrink, 10 * s, 3 * s, light)

	# Arms tucked
	_fill_rect(image, cx - 9 * s, cy + shrink, 3 * s, 8 * s, body_color)
	_fill_rect(image, cx + 6 * s, cy + shrink, 3 * s, 8 * s, body_color)

	# Head ducked
	_fill_circle(image, cx, cy - 5 * s + shrink, 5 * s, skin)
	_fill_circle(image, cx, cy - 7 * s + shrink, 4 * s, detail_color)
	_fill_rect(image, cx - 2 * s, cy - 6 * s + shrink, 2 * s, 1 * s, Color(0.15, 0.15, 0.2))
	_fill_rect(image, cx + 1 * s, cy - 6 * s + shrink, 2 * s, 1 * s, Color(0.15, 0.15, 0.2))

	# Motion lines behind
	_fill_rect(image, cx - 2 * s, cy + 14 * s, 1 * s, 5 * s, Color(1, 1, 1, 0.2))
	_fill_rect(image, cx + 2 * s, cy + 15 * s, 1 * s, 4 * s, Color(1, 1, 1, 0.15))

	return ImageTexture.create_from_image(image)

static func _draw_weapon(img: Image, cx: float, cy: float, s: float, bob: float, weapon: String) -> void:
	# Weapon-specific pose so the same character can visually change by class.
	match weapon:
		"sword":
			var blade := Color(0.8, 0.85, 0.9, 1.0)
			var hilt := Color(0.6, 0.5, 0.2, 1.0)
			_fill_rect(img, cx + 10 * s, cy - 14 * s + bob, 3 * s, 12 * s, blade)
			_fill_rect(img, cx + 10 * s, cy - 15 * s + bob, 3 * s, 2 * s, blade.lightened(0.2))
			_fill_rect(img, cx + 9 * s, cy - 2 * s + bob, 5 * s, 2 * s, hilt)
		"daggers":
			var blade := Color(0.75, 0.8, 0.75, 1.0)
			_fill_rect(img, cx - 9 * s, cy - 6 * s + bob, 2 * s, 8 * s, blade)
			_fill_rect(img, cx + 9 * s, cy - 6 * s + bob, 2 * s, 8 * s, blade)
			_fill_rect(img, cx - 9 * s, cy - 7 * s + bob, 2 * s, 2 * s, blade.lightened(0.2))
			_fill_rect(img, cx + 9 * s, cy - 7 * s + bob, 2 * s, 2 * s, blade.lightened(0.2))
		"staff":
			var wood := Color(0.5, 0.35, 0.2, 1.0)
			var orb := Color(0.6, 0.3, 1.0, 0.9)
			_fill_rect(img, cx + 10 * s, cy - 16 * s + bob, 2 * s, 28 * s, wood)
			_fill_circle(img, cx + 11 * s, cy - 17 * s + bob, 3 * s, orb)
			_fill_circle(img, cx + 11 * s, cy - 17 * s + bob, 1.5 * s, orb.lightened(0.3))

static func _draw_weapon_attack(img: Image, cx: float, cy: float, s: float, lean: float, arm_ext: float, weapon: String, swing: float) -> void:
	# Attack variant where weapon extends and rotates differently per class weapon type.
	match weapon:
		"sword":
			var blade := Color(0.8, 0.85, 0.9, 1.0)
			var blade_y: float = cy - 14 * s + lean + arm_ext - swing * 8.0
			_fill_rect(img, cx + 10 * s, blade_y, 3 * s, 14 * s, blade)
			_fill_rect(img, cx + 10 * s, blade_y - 2 * s, 3 * s, 2 * s, Color(1, 1, 1, 0.8))
		"daggers":
			var blade := Color(0.75, 0.8, 0.75, 1.0)
			var stab: float = swing * 6.0
			_fill_rect(img, cx - 9 * s, cy - 6 * s + lean - stab, 2 * s, 10 * s, blade)
			_fill_rect(img, cx + 9 * s, cy - 8 * s + lean + arm_ext, 2 * s, 10 * s, blade)
		"staff":
			var wood := Color(0.5, 0.35, 0.2, 1.0)
			var orb := Color(0.6, 0.3, 1.0, 0.9)
			_fill_rect(img, cx + 10 * s, cy - 18 * s + lean + arm_ext, 2 * s, 28 * s, wood)
			var orb_glow: float = 1.0 + swing * 0.5
			_fill_circle(img, cx + 11 * s, cy - 19 * s + lean + arm_ext, 3 * s * orb_glow, orb)
			_fill_circle(img, cx + 11 * s, cy - 19 * s + lean + arm_ext, 1.5 * s * orb_glow, Color(1, 1, 1, 0.5))

# ─── enemy sprite frames ───

static func create_slime_frames(body_color: Color) -> SpriteFrames:
	# Public factory for slime enemy animation states.
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

	var light := body_color.lightened(0.2)
	var dark := body_color.darkened(0.2)

	# idle: 4 frames, jiggle/pulse
	frames.add_animation(&"idle")
	frames.set_animation_speed(&"idle", 3.0)
	frames.set_animation_loop(&"idle", true)
	for i in range(4):
		var squish: float = sin(i * PI / 2.0) * 2.0
		var tex: Texture2D = _draw_slime_frame(48, body_color, light, dark, squish, 0.0)
		frames.add_frame(&"idle", tex)

	# run: 4 frames, bouncing
	frames.add_animation(&"run")
	frames.set_animation_speed(&"run", 6.0)
	frames.set_animation_loop(&"run", true)
	for i in range(4):
		var bounce: float = -absf(sin(i * PI / 2.0)) * 4.0
		var squish: float = sin(i * PI / 2.0) * 3.0
		var tex: Texture2D = _draw_slime_frame(48, body_color, light, dark, squish, bounce)
		frames.add_frame(&"run", tex)

	# attack: 3 frames, lunge
	frames.add_animation(&"attack")
	frames.set_animation_speed(&"attack", 6.0)
	frames.set_animation_loop(&"attack", false)
	var lunge_offsets: Array = [0.0, -5.0, -2.0]
	var lunge_squish: Array = [0.0, -3.0, 1.0]
	for i in range(3):
		var tex: Texture2D = _draw_slime_frame(48, body_color, light, dark, lunge_squish[i], lunge_offsets[i])
		frames.add_frame(&"attack", tex)

	return frames

static func _draw_slime_frame(size: int, body_color: Color, light: Color, dark: Color, squish: float, y_offset: float) -> Texture2D:
	# Creates one blob-like frame with squash/stretch animation parameters.
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0
	var cy: float = size / 2.0 + y_offset
	var s: float = size / 48.0

	# Shadow
	_fill_circle(image, cx, size / 2.0 + 10 * s, 9 * s, Color(0, 0, 0, 0.12))

	# Body blob — wider when squished down, taller when stretched
	var rx: float = 12 * s + squish * 0.5
	var ry: float = 10 * s - squish * 0.3
	# Approximate ellipse with two overlapping circles
	_fill_circle(image, cx, cy + 2 * s, rx, body_color)
	_fill_circle(image, cx, cy - 2 * s + squish * 0.3, ry, light)

	# Shiny highlight
	_fill_circle(image, cx - 3 * s, cy - 5 * s + squish * 0.2, 3 * s, light.lightened(0.3))
	_fill_circle(image, cx - 4 * s, cy - 6 * s + squish * 0.2, 1.5 * s, Color(1, 1, 1, 0.4))

	# Eyes
	_fill_circle(image, cx - 4 * s, cy - 3 * s, 3 * s, Color.WHITE)
	_fill_circle(image, cx + 4 * s, cy - 3 * s, 3 * s, Color.WHITE)
	# Pupils
	_fill_circle(image, cx - 4 * s, cy - 3.5 * s, 1.5 * s, Color(0.1, 0.1, 0.1))
	_fill_circle(image, cx + 4 * s, cy - 3.5 * s, 1.5 * s, Color(0.1, 0.1, 0.1))

	# Mouth — small dark arc
	_fill_rect(image, cx - 2 * s, cy + 2 * s, 4 * s, 1.5 * s, dark.darkened(0.3))

	return ImageTexture.create_from_image(image)

# ─── skeleton sprite frames ───

static func create_skeleton_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

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

static func _draw_skeleton_frame(size: int, bone: Color, dark: Color, metal: Color, bob: float, leg_offset: float) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0
	var cy: float = size / 2.0
	var s: float = size / 48.0

	# Shadow
	_fill_circle(image, cx, cy + 14 * s, 8 * s, Color(0, 0, 0, 0.1))

	# Legs (thin bones)
	_fill_rect(image, cx - 4 * s, cy + 6 * s + leg_offset, 2 * s, 10 * s, bone)
	_fill_rect(image, cx + 2 * s, cy + 6 * s - leg_offset, 2 * s, 10 * s, bone)
	# Knee joints
	_fill_circle(image, cx - 3 * s, cy + 6 * s + leg_offset, 2 * s, dark)
	_fill_circle(image, cx + 3 * s, cy + 6 * s - leg_offset, 2 * s, dark)

	# Ribcage (horizontal bars)
	_fill_rect(image, cx - 5 * s, cy - 2 * s + bob, 10 * s, 2 * s, bone)
	_fill_rect(image, cx - 4 * s, cy + 1 * s + bob, 8 * s, 2 * s, bone.darkened(0.1))
	_fill_rect(image, cx - 3 * s, cy + 4 * s + bob, 6 * s, 1 * s, bone.darkened(0.15))
	# Spine
	_fill_rect(image, cx - 1 * s, cy - 3 * s + bob, 2 * s, 10 * s, dark)

	# Shoulder bones
	_fill_circle(image, cx - 6 * s, cy - 2 * s + bob, 2.5 * s, bone)
	_fill_circle(image, cx + 6 * s, cy - 2 * s + bob, 2.5 * s, bone)

	# Arms (thin)
	_fill_rect(image, cx - 8 * s, cy - 1 * s + bob, 2 * s, 8 * s, bone)
	_fill_rect(image, cx + 6 * s, cy - 1 * s + bob, 2 * s, 8 * s, bone)

	# Skull
	_fill_circle(image, cx, cy - 8 * s + bob, 6 * s, bone)
	# Eye sockets (dark)
	_fill_circle(image, cx - 3 * s, cy - 9 * s + bob, 2 * s, Color(0.1, 0.0, 0.0))
	_fill_circle(image, cx + 3 * s, cy - 9 * s + bob, 2 * s, Color(0.1, 0.0, 0.0))
	# Glowing eyes
	_fill_circle(image, cx - 3 * s, cy - 9 * s + bob, 1 * s, Color(0.8, 0.2, 0.1, 0.9))
	_fill_circle(image, cx + 3 * s, cy - 9 * s + bob, 1 * s, Color(0.8, 0.2, 0.1, 0.9))
	# Jaw
	_fill_rect(image, cx - 3 * s, cy - 4 * s + bob, 6 * s, 2 * s, bone.darkened(0.15))

	# Sword (right hand)
	_fill_rect(image, cx + 8 * s, cy - 10 * s + bob, 2 * s, 10 * s, metal)
	_fill_rect(image, cx + 7 * s, cy - 1 * s + bob, 4 * s, 2 * s, metal.darkened(0.2))

	return ImageTexture.create_from_image(image)

static func _draw_skeleton_attack_frame(size: int, bone: Color, dark: Color, metal: Color, swing: float) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0
	var cy: float = size / 2.0
	var s: float = size / 48.0
	var lean: float = -2.0 * swing

	_fill_circle(image, cx, cy + 14 * s, 8 * s, Color(0, 0, 0, 0.1))
	_fill_rect(image, cx - 4 * s, cy + 6 * s, 2 * s, 10 * s, bone)
	_fill_rect(image, cx + 2 * s, cy + 6 * s, 2 * s, 10 * s, bone)
	_fill_rect(image, cx - 5 * s, cy - 2 * s + lean, 10 * s, 2 * s, bone)
	_fill_rect(image, cx - 1 * s, cy - 3 * s + lean, 2 * s, 10 * s, dark)
	_fill_circle(image, cx - 6 * s, cy - 2 * s + lean, 2.5 * s, bone)
	_fill_circle(image, cx + 6 * s, cy - 2 * s + lean, 2.5 * s, bone)
	_fill_rect(image, cx - 8 * s, cy - 1 * s + lean, 2 * s, 8 * s, bone)
	# Right arm extended
	var arm_ext: float = -6.0 * swing
	_fill_rect(image, cx + 6 * s, cy - 1 * s + lean + arm_ext, 2 * s, 8 * s, bone)
	_fill_circle(image, cx, cy - 8 * s + lean, 6 * s, bone)
	_fill_circle(image, cx - 3 * s, cy - 9 * s + lean, 1 * s, Color(0.8, 0.2, 0.1, 0.9))
	_fill_circle(image, cx + 3 * s, cy - 9 * s + lean, 1 * s, Color(0.8, 0.2, 0.1, 0.9))
	# Sword swinging forward
	_fill_rect(image, cx + 8 * s, cy - 14 * s + lean + arm_ext - swing * 6.0, 2 * s, 12 * s, metal)
	_fill_rect(image, cx + 8 * s, cy - 15 * s + lean + arm_ext - swing * 6.0, 2 * s, 2 * s, Color(1, 1, 1, 0.6))

	return ImageTexture.create_from_image(image)

# ─── fire imp sprite frames ───

static func create_imp_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

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

static func _draw_imp_frame(size: int, hover: float, wobble: float) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0 + wobble
	var cy: float = size / 2.0 + hover
	var s: float = size / 48.0

	var body := Color(0.9, 0.3, 0.1)
	var light := Color(1.0, 0.5, 0.2)
	var dark := Color(0.6, 0.15, 0.05)

	# Shadow
	_fill_circle(image, size / 2.0, size / 2.0 + 12 * s, 6 * s, Color(0, 0, 0, 0.1))

	# Body (small, round)
	_fill_circle(image, cx, cy + 2 * s, 8 * s, body)
	_fill_circle(image, cx, cy, 6 * s, light)

	# Horns
	_fill_rect(image, cx - 6 * s, cy - 10 * s, 2 * s, 6 * s, dark)
	_fill_rect(image, cx + 4 * s, cy - 10 * s, 2 * s, 6 * s, dark)
	_fill_rect(image, cx - 7 * s, cy - 11 * s, 2 * s, 2 * s, dark.lightened(0.1))
	_fill_rect(image, cx + 5 * s, cy - 11 * s, 2 * s, 2 * s, dark.lightened(0.1))

	# Eyes (glowing yellow)
	_fill_circle(image, cx - 3 * s, cy - 2 * s, 2.5 * s, Color(1.0, 0.9, 0.2))
	_fill_circle(image, cx + 3 * s, cy - 2 * s, 2.5 * s, Color(1.0, 0.9, 0.2))
	_fill_circle(image, cx - 3 * s, cy - 2 * s, 1 * s, Color(0.1, 0.0, 0.0))
	_fill_circle(image, cx + 3 * s, cy - 2 * s, 1 * s, Color(0.1, 0.0, 0.0))

	# Small legs/feet
	_fill_rect(image, cx - 4 * s, cy + 8 * s, 2 * s, 4 * s, dark)
	_fill_rect(image, cx + 2 * s, cy + 8 * s, 2 * s, 4 * s, dark)

	# Tail
	_fill_rect(image, cx + 6 * s, cy + 3 * s, 4 * s, 2 * s, dark)
	_fill_rect(image, cx + 9 * s, cy + 2 * s, 2 * s, 2 * s, light)

	return ImageTexture.create_from_image(image)

static func _draw_imp_attack_frame(size: int, glow: float) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0
	var cy: float = size / 2.0
	var s: float = size / 48.0

	var body := Color(0.9, 0.3, 0.1)
	var light := Color(1.0, 0.5 + glow * 0.3, 0.2 + glow * 0.2)

	_fill_circle(image, cx, cy + 2 * s, 8 * s, body)
	_fill_circle(image, cx, cy, 6 * s, light)

	# Horns
	_fill_rect(image, cx - 6 * s, cy - 10 * s, 2 * s, 6 * s, body.darkened(0.3))
	_fill_rect(image, cx + 4 * s, cy - 10 * s, 2 * s, 6 * s, body.darkened(0.3))

	# Eyes glowing brighter during attack
	var eye_glow := Color(1.0, 0.9 + glow * 0.1, 0.2 + glow * 0.3)
	_fill_circle(image, cx - 3 * s, cy - 2 * s, 3 * s, eye_glow)
	_fill_circle(image, cx + 3 * s, cy - 2 * s, 3 * s, eye_glow)

	# Fireball forming in front
	var orb_y: float = cy - 8 * s - glow * 4.0
	_fill_circle(image, cx, orb_y, (3 + glow * 2) * s, Color(1.0, 0.6, 0.1, 0.8))
	_fill_circle(image, cx, orb_y, (1.5 + glow) * s, Color(1.0, 1.0, 0.7, 0.6))

	_fill_rect(image, cx - 4 * s, cy + 8 * s, 2 * s, 4 * s, body.darkened(0.3))
	_fill_rect(image, cx + 2 * s, cy + 8 * s, 2 * s, 4 * s, body.darkened(0.3))

	return ImageTexture.create_from_image(image)

# ─── shadow wraith sprite frames ───

static func create_wraith_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

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

static func _draw_wraith_frame(size: int, sway: float, hover: float) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0 + sway
	var cy: float = size / 2.0 + hover
	var s: float = size / 48.0

	var body := Color(0.2, 0.08, 0.3, 0.8)
	var light := Color(0.35, 0.15, 0.5, 0.6)
	var wisp := Color(0.15, 0.05, 0.25, 0.4)

	# Wispy tail (bottom, fading)
	_fill_circle(image, cx, cy + 10 * s, 5 * s, wisp)
	_fill_circle(image, cx - 2 * s, cy + 13 * s, 3 * s, Color(wisp.r, wisp.g, wisp.b, 0.2))
	_fill_circle(image, cx + 2 * s, cy + 14 * s, 2 * s, Color(wisp.r, wisp.g, wisp.b, 0.15))

	# Body (tall, narrow ellipse-like)
	_fill_circle(image, cx, cy + 2 * s, 8 * s, body)
	_fill_circle(image, cx, cy - 4 * s, 7 * s, light)
	_fill_circle(image, cx, cy + 6 * s, 6 * s, wisp)

	# Hood/cloak top
	_fill_circle(image, cx, cy - 8 * s, 7 * s, body)
	_fill_circle(image, cx, cy - 10 * s, 5 * s, Color(0.1, 0.03, 0.15, 0.9))

	# Glowing eyes
	_fill_circle(image, cx - 3 * s, cy - 7 * s, 2 * s, Color(0.6, 0.1, 1.0, 0.9))
	_fill_circle(image, cx + 3 * s, cy - 7 * s, 2 * s, Color(0.6, 0.1, 1.0, 0.9))
	_fill_circle(image, cx - 3 * s, cy - 7 * s, 1 * s, Color(1.0, 0.5, 1.0, 0.7))
	_fill_circle(image, cx + 3 * s, cy - 7 * s, 1 * s, Color(1.0, 0.5, 1.0, 0.7))

	# Spectral arms (wispy)
	_fill_rect(image, cx - 10 * s, cy - 2 * s, 3 * s, 6 * s, wisp)
	_fill_rect(image, cx + 7 * s, cy - 2 * s, 3 * s, 6 * s, wisp)
	_fill_circle(image, cx - 9 * s, cy + 4 * s, 2 * s, light)
	_fill_circle(image, cx + 9 * s, cy + 4 * s, 2 * s, light)

	return ImageTexture.create_from_image(image)

# ─── golem boss sprite frames ───

static func create_golem_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

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

static func _draw_golem_frame(size: int, bob: float, leg_offset: float) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0
	var cy: float = size / 2.0
	var s: float = size / 48.0

	var stone := Color(0.5, 0.45, 0.4)
	var light := Color(0.6, 0.55, 0.5)
	var dark := Color(0.3, 0.25, 0.2)
	var crack := Color(0.8, 0.4, 0.1, 0.6)

	# Shadow
	_fill_circle(image, cx, cy + 14 * s, 10 * s, Color(0, 0, 0, 0.15))

	# Legs (thick, stumpy)
	_fill_rect(image, cx - 7 * s, cy + 4 * s + leg_offset, 5 * s, 10 * s, dark)
	_fill_rect(image, cx + 2 * s, cy + 4 * s - leg_offset, 5 * s, 10 * s, dark)
	# Feet
	_fill_rect(image, cx - 8 * s, cy + 12 * s + leg_offset, 7 * s, 3 * s, dark.darkened(0.2))
	_fill_rect(image, cx + 1 * s, cy + 12 * s - leg_offset, 7 * s, 3 * s, dark.darkened(0.2))

	# Body (large blocky torso)
	_fill_rect(image, cx - 10 * s, cy - 8 * s + bob, 20 * s, 14 * s, stone)
	_fill_rect(image, cx - 8 * s, cy - 6 * s + bob, 16 * s, 4 * s, light)
	# Cracks in the stone
	_fill_rect(image, cx - 3 * s, cy - 5 * s + bob, 1 * s, 8 * s, crack)
	_fill_rect(image, cx + 4 * s, cy - 3 * s + bob, 1 * s, 6 * s, crack)

	# Arms (massive, hanging low)
	_fill_rect(image, cx - 14 * s, cy - 4 * s + bob, 5 * s, 14 * s, stone)
	_fill_rect(image, cx + 9 * s, cy - 4 * s + bob, 5 * s, 14 * s, stone)
	# Fists
	_fill_circle(image, cx - 12 * s, cy + 10 * s + bob, 4 * s, dark)
	_fill_circle(image, cx + 12 * s, cy + 10 * s + bob, 4 * s, dark)

	# Head (small for body, rocky)
	_fill_circle(image, cx, cy - 12 * s + bob, 6 * s, stone.lightened(0.1))
	# Eyes (glowing orange)
	_fill_rect(image, cx - 4 * s, cy - 13 * s + bob, 3 * s, 2 * s, Color(0.9, 0.5, 0.1))
	_fill_rect(image, cx + 1 * s, cy - 13 * s + bob, 3 * s, 2 * s, Color(0.9, 0.5, 0.1))
	# Brow ridge
	_fill_rect(image, cx - 5 * s, cy - 15 * s + bob, 10 * s, 2 * s, dark)

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

	_fill_circle(image, cx, cy + 14 * s, 10 * s, Color(0, 0, 0, 0.15))
	# Legs planted
	_fill_rect(image, cx - 7 * s, cy + 4 * s, 5 * s, 10 * s, dark)
	_fill_rect(image, cx + 2 * s, cy + 4 * s, 5 * s, 10 * s, dark)
	# Body
	_fill_rect(image, cx - 10 * s, cy - 8 * s + lean, 20 * s, 14 * s, stone)
	_fill_rect(image, cx - 8 * s, cy - 6 * s + lean, 16 * s, 4 * s, light)
	# Arms raised then slamming
	var arm_raise: float = -10.0 * (1.0 - slam)
	_fill_rect(image, cx - 14 * s, cy - 4 * s + lean + arm_raise, 5 * s, 14 * s, stone)
	_fill_rect(image, cx + 9 * s, cy - 4 * s + lean + arm_raise, 5 * s, 14 * s, stone)
	_fill_circle(image, cx - 12 * s, cy + 10 * s + lean + arm_raise, 4 * s, dark)
	_fill_circle(image, cx + 12 * s, cy + 10 * s + lean + arm_raise, 4 * s, dark)
	# Head
	_fill_circle(image, cx, cy - 12 * s + lean, 6 * s, stone.lightened(0.1))
	# Eyes glow brighter during attack
	var eye_bright := 0.5 + slam * 0.5
	_fill_rect(image, cx - 4 * s, cy - 13 * s + lean, 3 * s, 2 * s, Color(1.0, eye_bright, 0.1))
	_fill_rect(image, cx + 1 * s, cy - 13 * s + lean, 3 * s, 2 * s, Color(1.0, eye_bright, 0.1))

	return ImageTexture.create_from_image(image)
