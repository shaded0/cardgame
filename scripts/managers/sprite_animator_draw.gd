extends RefCounted

static func new_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	return frames

static func fill_circle(img: Image, cx: float, cy: float, r: float, col: Color) -> void:
	for dy in range(int(-r) - 1, int(r) + 2):
		for dx in range(int(-r) - 1, int(r) + 2):
			var px: int = int(cx) + dx
			var py: int = int(cy) + dy
			if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
				if dx * dx + dy * dy <= r * r:
					img.set_pixel(px, py, col)

static func fill_rect(img: Image, rx: float, ry: float, rw: float, rh: float, col: Color) -> void:
	for dy in range(int(rh)):
		for dx in range(int(rw)):
			var px: int = int(rx) + dx
			var py: int = int(ry) + dy
			if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
				img.set_pixel(px, py, col)
