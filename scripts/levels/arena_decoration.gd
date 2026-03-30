class_name ArenaDecoration
extends Node2D

## Visual-only arena decorations — no collision, no gameplay impact.
## Braziers include fake point lighting via additive-blend sprites.

enum DecorType { BRAZIER, RUBBLE, BONES, CHAIN, LAVA_POOL, TORCH_WALL, BANNER, ALTAR, BLOOD_STAIN, SKULL_PILE }

var _accent_color: Color = Color(0.8, 0.45, 0.15)

func setup(type: DecorType, pos: Vector2, accent: Color = Color(0.8, 0.45, 0.15)) -> void:
	global_position = pos
	_accent_color = accent
	z_index = -1

	match type:
		DecorType.BRAZIER:
			_build_brazier()
		DecorType.RUBBLE:
			_build_rubble()
		DecorType.BONES:
			_build_bones()
		DecorType.CHAIN:
			_build_chain()
		DecorType.LAVA_POOL:
			_build_lava_pool()
		DecorType.TORCH_WALL:
			_build_torch_wall()
		DecorType.BANNER:
			_build_banner()
		DecorType.ALTAR:
			_build_altar()
		DecorType.BLOOD_STAIN:
			_build_blood_stain()
		DecorType.SKULL_PILE:
			_build_skull_pile()

func _build_brazier() -> void:
	# Stone base + bowl
	var base_sprite := Sprite2D.new()
	base_sprite.texture = _make_brazier_texture()
	base_sprite.offset = Vector2(0, -12)
	base_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(base_sprite)

	# Animated flame
	var flame := Sprite2D.new()
	flame.texture = _make_flame_texture()
	flame.offset = Vector2(0, -24)
	flame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(flame)
	_animate_flame(flame)

	# Fake point light — large soft additive circle
	var glow := Sprite2D.new()
	glow.texture = _make_glow_texture(64)
	glow.offset = Vector2(0, -18)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat
	glow.modulate = Color(_accent_color.r, _accent_color.g, _accent_color.b, 0.15)
	glow.z_index = -1
	add_child(glow)
	_animate_glow(glow)

func _build_rubble() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _make_rubble_texture()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.modulate.a = 0.7
	sprite.rotation = randf() * TAU
	add_child(sprite)

func _build_bones() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _make_bones_texture()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.modulate.a = 0.6
	sprite.rotation = randf() * TAU
	add_child(sprite)

func _build_chain() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _make_chain_texture()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.modulate.a = 0.5
	add_child(sprite)

func _build_lava_pool() -> void:
	var pool := _LavaPoolDraw.new()
	pool.accent = _accent_color
	add_child(pool)
	# Pulse animation
	var tween := pool.create_tween().set_loops()
	tween.tween_property(pool, "modulate:a", 0.5, 1.5).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(pool, "modulate:a", 0.8, 1.5).set_ease(Tween.EASE_IN_OUT)

func _animate_flame(flame: Sprite2D) -> void:
	if not is_instance_valid(flame) or not flame.is_inside_tree():
		return
	var tween := flame.create_tween().set_loops()
	tween.tween_property(flame, "scale", Vector2(1.1, 1.2), randf_range(0.15, 0.25))
	tween.tween_property(flame, "scale", Vector2(0.9, 0.95), randf_range(0.15, 0.25))
	tween.tween_property(flame, "scale", Vector2(1.05, 1.1), randf_range(0.1, 0.2))
	tween.tween_property(flame, "scale", Vector2(1.0, 1.0), randf_range(0.1, 0.2))

func _animate_glow(glow: Sprite2D) -> void:
	if not is_instance_valid(glow) or not glow.is_inside_tree():
		return
	var base_alpha: float = glow.modulate.a
	var tween := glow.create_tween().set_loops()
	tween.tween_property(glow, "modulate:a", base_alpha * 1.3, randf_range(0.8, 1.5)).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(glow, "modulate:a", base_alpha * 0.7, randf_range(0.8, 1.5)).set_ease(Tween.EASE_IN_OUT)

# --- Texture generation ---

func _make_brazier_texture() -> ImageTexture:
	var w: int = 16
	var h: int = 24
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	# Stone base (bottom half)
	for x in range(w):
		for y in range(h / 2, h):
			var cx: float = w / 2.0
			var dist: float = absf(float(x) - cx)
			if dist < 6.0:
				var shade: float = 0.35 - dist * 0.02
				img.set_pixel(x, y, Color(shade, shade * 0.95, shade * 0.9, 1.0))
	# Bowl rim (middle)
	for x in range(w):
		var cx: float = w / 2.0
		var dist: float = absf(float(x) - cx)
		if dist < 7.0:
			for y in range(h / 2 - 3, h / 2):
				img.set_pixel(x, y, Color(0.4, 0.38, 0.35, 1.0))
	return ImageTexture.create_from_image(img)

func _make_flame_texture() -> ImageTexture:
	var w: int = 8
	var h: int = 10
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var cx: float = w / 2.0
	for x in range(w):
		for y in range(h):
			var dx: float = absf(float(x) - cx)
			var dy: float = float(y) / float(h)
			var flame_width: float = (1.0 - dy) * 4.0
			if dx < flame_width:
				var t: float = dx / maxf(flame_width, 0.01)
				var r: float = 1.0
				var g: float = lerpf(0.85, 0.3, dy)
				var b: float = lerpf(0.2, 0.0, dy)
				var a: float = (1.0 - t) * (1.0 - dy * 0.5)
				img.set_pixel(x, y, Color(r, g, b, a))
	return ImageTexture.create_from_image(img)

func _make_glow_texture(size: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size / 2.0, size / 2.0)
	for x in range(size):
		for y in range(size):
			var dist: float = Vector2(x, y).distance_to(center) / (size / 2.0)
			var alpha: float = clampf(1.0 - dist * dist, 0.0, 1.0)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(img)

func _make_rubble_texture() -> ImageTexture:
	var w: int = 20
	var h: int = 12
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	# 4-6 random small stone chunks
	for _chunk in range(randi_range(4, 6)):
		var cx: int = randi_range(2, w - 3)
		var cy: int = randi_range(2, h - 3)
		var cw: int = randi_range(2, 5)
		var ch: int = randi_range(2, 4)
		var shade: float = randf_range(0.25, 0.45)
		for x in range(maxi(cx - cw / 2, 0), mini(cx + cw / 2, w)):
			for y in range(maxi(cy - ch / 2, 0), mini(cy + ch / 2, h)):
				img.set_pixel(x, y, Color(shade, shade * 0.9, shade * 0.8, 0.9))
	return ImageTexture.create_from_image(img)

func _make_bones_texture() -> ImageTexture:
	var w: int = 16
	var h: int = 10
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var bone_color := Color(0.75, 0.72, 0.65, 0.7)
	# Two crossed diagonal bones
	for i in range(mini(w, h)):
		if i < w and i < h:
			img.set_pixel(i, i * h / w, bone_color)
		var mirror_x: int = w - 1 - i
		if mirror_x >= 0 and mirror_x < w and i < h:
			img.set_pixel(mirror_x, i * h / w, bone_color)
	# Small circle at center (joint)
	var cx: int = w / 2
	var cy: int = h / 2
	for x in range(maxi(cx - 2, 0), mini(cx + 2, w)):
		for y in range(maxi(cy - 1, 0), mini(cy + 1, h)):
			img.set_pixel(x, y, bone_color)
	return ImageTexture.create_from_image(img)

func _make_chain_texture() -> ImageTexture:
	var w: int = 6
	var h: int = 32
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	# Alternating chain links
	for link in range(h / 6):
		var y_base: int = link * 6
		var is_wide: bool = link % 2 == 0
		var shade: float = 0.5 if is_wide else 0.4
		for y in range(y_base, mini(y_base + 5, h)):
			var link_w: int = 4 if is_wide else 3
			var x_start: int = (w - link_w) / 2
			for x in range(x_start, x_start + link_w):
				# Hollow oval shape
				var on_edge: bool = x == x_start or x == x_start + link_w - 1 or y == y_base or y == y_base + 4
				if on_edge:
					img.set_pixel(x, y, Color(shade, shade, shade * 0.95, 0.8))
	return ImageTexture.create_from_image(img)

## Inner class for lava pool drawing.
class _LavaPoolDraw extends Node2D:
	var accent: Color = Color(1.0, 0.5, 0.1)

	func _draw() -> void:
		# Isometric ellipse
		var rx: float = 30.0
		var ry: float = 15.0
		var segments: int = 16
		var points := PackedVector2Array()
		for i in range(segments + 1):
			var angle: float = float(i) / float(segments) * TAU
			points.append(Vector2(cos(angle) * rx, sin(angle) * ry))
		var pool_color := Color(accent.r, accent.g * 0.6, accent.b * 0.3, 0.6)
		draw_colored_polygon(points, pool_color)
		# Brighter center
		var inner_points := PackedVector2Array()
		for i in range(segments + 1):
			var angle: float = float(i) / float(segments) * TAU
			inner_points.append(Vector2(cos(angle) * rx * 0.5, sin(angle) * ry * 0.5))
		draw_colored_polygon(inner_points, Color(accent.r, accent.g, accent.b * 0.5, 0.4))
