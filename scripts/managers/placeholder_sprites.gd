class_name PlaceholderSprites
extends RefCounted

## Generates simple colored rectangle textures for prototyping.

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

static func create_arrow_texture(size: int, color: Color) -> ImageTexture:
	## Creates an upward-pointing arrow/triangle sprite. Rotate to face direction.
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center_x: float = size / 2.0
	var top_y: float = 1.0
	var bot_y: float = size - 2.0
	var half_w: float = size / 3.0

	for y in range(size):
		for x in range(size):
			# Triangle: top point at center, widens toward bottom
			var progress: float = float(y - int(top_y)) / (bot_y - top_y)
			if progress < 0.0 or progress > 1.0:
				continue
			var width_at_y: float = half_w * progress
			var dist_from_center: float = absf(float(x) - center_x)
			if dist_from_center <= width_at_y:
				# Brighter at the tip
				var brightness: float = 1.0 - progress * 0.3
				var px_color := Color(color.r * brightness, color.g * brightness, color.b * brightness, color.a)
				image.set_pixel(x, y, px_color)

	# Add a small dot at center for body feel
	var body_y: int = int(size * 0.55)
	var body_r: int = max(1, size / 8)
	for dy in range(-body_r, body_r + 1):
		for dx in range(-body_r, body_r + 1):
			var px: int = int(center_x) + dx
			var py: int = body_y + dy
			if px >= 0 and px < size and py >= 0 and py < size:
				if dx * dx + dy * dy <= body_r * body_r:
					image.set_pixel(px, py, color)

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
