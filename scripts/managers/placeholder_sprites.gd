class_name PlaceholderSprites
extends RefCounted

## Generates placeholder textures for prototyping.

static func create_rect_texture(width: int, height: int, color: Color) -> ImageTexture:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)

static func create_circle_texture(radius: int, color: Color) -> ImageTexture:
	var size := radius * 2
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(radius, radius)
	for x in range(size):
		for y in range(size):
			if Vector2(x, y).distance_to(center) <= radius:
				image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)

static func create_humanoid_texture(size: int, body_color: Color, detail_color: Color, weapon_type: String = "sword") -> ImageTexture:
	## Creates a top-down humanoid sprite facing upward.
	## weapon_type: "sword", "daggers", "staff"
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0
	var cy: float = size / 2.0

	var skin_color := Color(0.9, 0.75, 0.6, 1.0)
	var dark_body := body_color.darkened(0.3)
	var light_body := body_color.lightened(0.2)
	var outline := body_color.darkened(0.5)

	# Helper to draw filled circle
	var draw_circle_fn := func(img: Image, center_pos: Vector2, radius: float, col: Color) -> void:
		for dy in range(int(-radius) - 1, int(radius) + 2):
			for dx in range(int(-radius) - 1, int(radius) + 2):
				var px: int = int(center_pos.x) + dx
				var py: int = int(center_pos.y) + dy
				if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
					if dx * dx + dy * dy <= radius * radius:
						img.set_pixel(px, py, col)

	# Helper to draw filled rect
	var draw_rect_fn := func(img: Image, rect_pos: Vector2, rect_size: Vector2, col: Color) -> void:
		for dy in range(int(rect_size.y)):
			for dx in range(int(rect_size.x)):
				var px: int = int(rect_pos.x) + dx
				var py: int = int(rect_pos.y) + dy
				if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
					img.set_pixel(px, py, col)

	var s: float = size / 48.0  # Scale factor relative to base 48px

	# === LEGS (bottom, behind body) ===
	# Left leg
	draw_rect_fn.call(image, Vector2(cx - 5 * s, cy + 6 * s), Vector2(4 * s, 10 * s), dark_body)
	# Right leg
	draw_rect_fn.call(image, Vector2(cx + 1 * s, cy + 6 * s), Vector2(4 * s, 10 * s), dark_body)
	# Boots
	draw_rect_fn.call(image, Vector2(cx - 5 * s, cy + 13 * s), Vector2(4 * s, 4 * s), outline)
	draw_rect_fn.call(image, Vector2(cx + 1 * s, cy + 13 * s), Vector2(4 * s, 4 * s), outline)

	# === BODY / TORSO ===
	# Main torso
	draw_rect_fn.call(image, Vector2(cx - 6 * s, cy - 4 * s), Vector2(12 * s, 12 * s), body_color)
	# Chest highlight
	draw_rect_fn.call(image, Vector2(cx - 4 * s, cy - 3 * s), Vector2(8 * s, 4 * s), light_body)
	# Belt
	draw_rect_fn.call(image, Vector2(cx - 6 * s, cy + 5 * s), Vector2(12 * s, 3 * s), outline)

	# === ARMS ===
	# Left arm
	draw_rect_fn.call(image, Vector2(cx - 10 * s, cy - 2 * s), Vector2(4 * s, 10 * s), body_color)
	draw_circle_fn.call(image, Vector2(cx - 8 * s, cy + 8 * s), 2.5 * s, skin_color)  # Hand
	# Right arm
	draw_rect_fn.call(image, Vector2(cx + 6 * s, cy - 2 * s), Vector2(4 * s, 10 * s), body_color)
	draw_circle_fn.call(image, Vector2(cx + 8 * s, cy + 8 * s), 2.5 * s, skin_color)  # Hand

	# === SHOULDER PADS ===
	draw_circle_fn.call(image, Vector2(cx - 8 * s, cy - 2 * s), 3.5 * s, detail_color)
	draw_circle_fn.call(image, Vector2(cx + 8 * s, cy - 2 * s), 3.5 * s, detail_color)

	# === HEAD ===
	# Neck
	draw_rect_fn.call(image, Vector2(cx - 2 * s, cy - 7 * s), Vector2(4 * s, 4 * s), skin_color)
	# Head circle
	draw_circle_fn.call(image, Vector2(cx, cy - 10 * s), 6 * s, skin_color)
	# Hair/helmet top
	draw_circle_fn.call(image, Vector2(cx, cy - 12 * s), 5 * s, detail_color)
	# Eyes
	draw_rect_fn.call(image, Vector2(cx - 3 * s, cy - 11 * s), Vector2(2 * s, 2 * s), Color(0.15, 0.15, 0.2, 1.0))
	draw_rect_fn.call(image, Vector2(cx + 1 * s, cy - 11 * s), Vector2(2 * s, 2 * s), Color(0.15, 0.15, 0.2, 1.0))

	# === WEAPON (extends upward = forward when rotated) ===
	match weapon_type:
		"sword":
			# Sword blade pointing up from right hand
			var blade_color := Color(0.8, 0.85, 0.9, 1.0)
			var hilt_color := Color(0.6, 0.5, 0.2, 1.0)
			draw_rect_fn.call(image, Vector2(cx + 10 * s, cy - 8 * s), Vector2(3 * s, 6 * s), blade_color)
			draw_rect_fn.call(image, Vector2(cx + 10 * s, cy - 14 * s), Vector2(3 * s, 6 * s), blade_color.lightened(0.1))
			draw_rect_fn.call(image, Vector2(cx + 9 * s, cy - 2 * s), Vector2(5 * s, 2 * s), hilt_color)  # Guard
		"daggers":
			# Two short daggers
			var blade_color := Color(0.75, 0.8, 0.75, 1.0)
			draw_rect_fn.call(image, Vector2(cx - 9 * s, cy - 6 * s), Vector2(2 * s, 8 * s), blade_color)
			draw_rect_fn.call(image, Vector2(cx + 9 * s, cy - 6 * s), Vector2(2 * s, 8 * s), blade_color)
		"staff":
			# Staff along the right side
			var staff_color := Color(0.5, 0.35, 0.2, 1.0)
			var orb_color := Color(0.6, 0.3, 1.0, 0.9)
			draw_rect_fn.call(image, Vector2(cx + 10 * s, cy - 16 * s), Vector2(2 * s, 28 * s), staff_color)
			draw_circle_fn.call(image, Vector2(cx + 11 * s, cy - 17 * s), 3 * s, orb_color)

	return ImageTexture.create_from_image(image)

static func create_enemy_texture(size: int, body_color: Color, enemy_type: String = "slime") -> ImageTexture:
	## Creates a top-down enemy sprite.
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0
	var cy: float = size / 2.0
	var s: float = size / 48.0

	var draw_circle_fn := func(img: Image, center_pos: Vector2, radius: float, col: Color) -> void:
		for dy in range(int(-radius) - 1, int(radius) + 2):
			for dx in range(int(-radius) - 1, int(radius) + 2):
				var px: int = int(center_pos.x) + dx
				var py: int = int(center_pos.y) + dy
				if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
					if dx * dx + dy * dy <= radius * radius:
						img.set_pixel(px, py, col)

	var draw_rect_fn := func(img: Image, rect_pos: Vector2, rect_size: Vector2, col: Color) -> void:
		for dy in range(int(rect_size.y)):
			for dx in range(int(rect_size.x)):
				var px: int = int(rect_pos.x) + dx
				var py: int = int(rect_pos.y) + dy
				if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
					img.set_pixel(px, py, col)

	match enemy_type:
		"slime":
			var light := body_color.lightened(0.2)
			var dark := body_color.darkened(0.2)
			# Blob body
			draw_circle_fn.call(image, Vector2(cx, cy + 2 * s), 12 * s, body_color)
			draw_circle_fn.call(image, Vector2(cx, cy - 2 * s), 10 * s, light)
			# Shiny spot
			draw_circle_fn.call(image, Vector2(cx - 3 * s, cy - 5 * s), 3 * s, light.lightened(0.3))
			# Eyes (facing up = forward)
			draw_circle_fn.call(image, Vector2(cx - 4 * s, cy - 4 * s), 2.5 * s, Color.WHITE)
			draw_circle_fn.call(image, Vector2(cx + 4 * s, cy - 4 * s), 2.5 * s, Color.WHITE)
			draw_rect_fn.call(image, Vector2(cx - 4 * s, cy - 4 * s), Vector2(2 * s, 2 * s), Color(0.1, 0.1, 0.1, 1.0))
			draw_rect_fn.call(image, Vector2(cx + 3 * s, cy - 4 * s), Vector2(2 * s, 2 * s), Color(0.1, 0.1, 0.1, 1.0))
			# Shadow underneath
			draw_circle_fn.call(image, Vector2(cx, cy + 10 * s), 8 * s, Color(0, 0, 0, 0.15))

	return ImageTexture.create_from_image(image)

static func create_diamond_texture(width: int, height: int, color: Color) -> ImageTexture:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var cx := width / 2.0
	var cy := height / 2.0
	for x in range(width):
		for y in range(height):
			var dx: float = absf(float(x) - cx) / cx
			var dy: float = absf(float(y) - cy) / cy
			if dx + dy <= 1.0:
				image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)
