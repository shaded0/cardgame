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
