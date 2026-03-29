class_name Obstacle
extends StaticBody2D

## Arena obstacle — blocks movement and projectiles.
## Call setup() after instancing to set type and size.

enum ObstacleType { PILLAR, WALL_H, WALL_V, CRATE }

var obstacle_type: ObstacleType = ObstacleType.PILLAR

func setup(type: ObstacleType, pos: Vector2) -> void:
	obstacle_type = type
	global_position = pos

	# Collision layers: block player (1), enemies (2), player projectiles (4), enemy projectiles (64)
	collision_layer = 1 | 2
	collision_mask = 0

	var shape := CollisionShape2D.new()
	var sprite := Sprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	match type:
		ObstacleType.PILLAR:
			var rect := RectangleShape2D.new()
			rect.size = Vector2(32, 24)
			shape.shape = rect
			sprite.texture = _make_pillar_texture()
			sprite.offset = Vector2(0, -16)
		ObstacleType.WALL_H:
			var rect := RectangleShape2D.new()
			rect.size = Vector2(96, 20)
			shape.shape = rect
			sprite.texture = _make_wall_texture(96, 32)
			sprite.offset = Vector2(0, -10)
		ObstacleType.WALL_V:
			var rect := RectangleShape2D.new()
			rect.size = Vector2(20, 96)
			shape.shape = rect
			sprite.texture = _make_wall_texture(20, 96)
			sprite.offset = Vector2(0, -10)
		ObstacleType.CRATE:
			var rect := RectangleShape2D.new()
			rect.size = Vector2(40, 30)
			shape.shape = rect
			sprite.texture = _make_crate_texture()
			sprite.offset = Vector2(0, -12)

	add_child(shape)
	add_child(sprite)

	# Drop shadow beneath obstacle
	var shadow := Sprite2D.new()
	var shadow_w: int = int(shape.shape.size.x * 1.2)
	var shadow_h: int = int(shape.shape.size.y * 0.6)
	shadow.texture = PlaceholderSprites.create_shadow_texture(maxi(shadow_w, 8), maxi(shadow_h, 6))
	shadow.offset = Vector2(0, 4)
	shadow.z_index = -2
	shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(shadow)

	# Area2D detector to block projectiles on contact.
	var blocker := Area2D.new()
	blocker.collision_layer = 0  # Not a body — pure detector
	blocker.collision_mask = 4 | 64  # Detect player and enemy projectiles
	var blocker_shape := CollisionShape2D.new()
	blocker_shape.shape = shape.shape.duplicate()
	blocker.add_child(blocker_shape)
	blocker.area_entered.connect(_on_projectile_hit)
	add_child(blocker)

func _on_projectile_hit(area: Area2D) -> void:
	# Destroy projectiles that hit this obstacle
	if area.has_method("receive_hit"):
		return  # It's a hurtbox, not a projectile
	area.queue_free()

func _make_pillar_texture() -> ImageTexture:
	var w: int = 32
	var h: int = 48
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	# Base
	for x in range(w):
		for y in range(h):
			var cx: float = w / 2.0
			var dist: float = absf(float(x) - cx)
			if dist < 12 and y > 8:
				var shade: float = 1.0 - dist / 20.0
				img.set_pixel(x, y, Color(0.45 * shade, 0.42 * shade, 0.38 * shade, 1.0))
			# Top cap
			if dist < 14 and y >= 4 and y <= 12:
				img.set_pixel(x, y, Color(0.55, 0.52, 0.48, 1.0))
	return ImageTexture.create_from_image(img)

func _make_wall_texture(w: int, h: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for x in range(w):
		for y in range(h):
			var brick: bool = (x / 12 + y / 8) % 2 == 0
			if brick:
				img.set_pixel(x, y, Color(0.4, 0.35, 0.3, 1.0))
			else:
				img.set_pixel(x, y, Color(0.35, 0.3, 0.25, 1.0))
	return ImageTexture.create_from_image(img)

func _make_crate_texture() -> ImageTexture:
	var w: int = 40
	var h: int = 40
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for x in range(w):
		for y in range(h):
			if x < 2 or x >= w - 2 or y < 2 or y >= h - 2:
				img.set_pixel(x, y, Color(0.3, 0.2, 0.1, 1.0))
			else:
				img.set_pixel(x, y, Color(0.55, 0.4, 0.2, 1.0))
	# Cross boards
	for i in range(min(w, h)):
		if i < w and i < h:
			img.set_pixel(i, i, Color(0.35, 0.25, 0.12, 1.0))
		if i < w and h - 1 - i >= 0:
			img.set_pixel(i, h - 1 - i, Color(0.35, 0.25, 0.12, 1.0))
	return ImageTexture.create_from_image(img)
