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

func _build_torch_wall() -> void:
	# Iron bracket mount
	var bracket := Sprite2D.new()
	bracket.texture = _make_torch_bracket_texture()
	bracket.offset = Vector2(0, -10)
	bracket.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(bracket)

	# Flame — reuse existing flame texture, slightly smaller
	var flame := Sprite2D.new()
	flame.texture = _make_flame_texture()
	flame.offset = Vector2(0, -26)
	flame.scale = Vector2(0.8, 0.8)
	flame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(flame)
	_animate_flame(flame)

	# Glow — smaller than brazier
	var glow := Sprite2D.new()
	glow.texture = _make_glow_texture(40)
	glow.offset = Vector2(0, -20)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat
	glow.modulate = Color(_accent_color.r, _accent_color.g, _accent_color.b, 0.12)
	glow.z_index = -1
	add_child(glow)
	_animate_glow(glow)

func _build_banner() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _make_banner_texture()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = 0
	add_child(sprite)
	# Gentle sway animation
	var tween := sprite.create_tween().set_loops()
	var period: float = randf_range(3.0, 4.5)
	tween.tween_property(sprite, "rotation", 0.05, period * 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "rotation", -0.05, period * 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _build_altar() -> void:
	var base_sprite := Sprite2D.new()
	base_sprite.texture = _make_altar_texture()
	base_sprite.offset = Vector2(0, -10)
	base_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(base_sprite)

	# Accent glow on top
	var glow := Sprite2D.new()
	glow.texture = _make_glow_texture(32)
	glow.offset = Vector2(0, -18)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat
	glow.modulate = Color(_accent_color.r, _accent_color.g, _accent_color.b, 0.08)
	glow.z_index = -1
	add_child(glow)
	_animate_glow(glow)

func _build_blood_stain() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _make_blood_stain_texture()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = -2
	sprite.rotation = randf() * TAU
	sprite.modulate.a = randf_range(0.3, 0.5)
	add_child(sprite)

func _build_skull_pile() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _make_skull_pile_texture()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.modulate.a = 0.65
	sprite.rotation = randf() * TAU
	add_child(sprite)

func _make_torch_bracket_texture() -> ImageTexture:
	var w: int = 8
	var h: int = 16
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var iron := Color(0.3, 0.28, 0.25, 1.0)
	var iron_light := Color(0.38, 0.35, 0.32, 1.0)
	# Vertical bar
	for y in range(4, h):
		img.set_pixel(3, y, iron)
		img.set_pixel(4, y, iron_light)
	# Horizontal shelf at top
	for x in range(1, 7):
		img.set_pixel(x, 4, iron_light)
		img.set_pixel(x, 5, iron)
	# Small cup/holder at top
	for x in range(2, 6):
		img.set_pixel(x, 3, iron)
	return ImageTexture.create_from_image(img)

func _make_banner_texture() -> ImageTexture:
	var w: int = 12
	var h: int = 24
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rod_color := Color(0.3, 0.2, 0.1, 1.0)
	var fabric := _accent_color.darkened(0.2)
	var border := _accent_color.darkened(0.4)
	var emblem := _accent_color.lightened(0.15)

	# Top rod
	for x in range(w):
		img.set_pixel(x, 0, rod_color)
		img.set_pixel(x, 1, rod_color)

	# Banner body
	for x in range(w):
		for y in range(2, h - 2):
			if x < 1 or x >= w - 1:
				img.set_pixel(x, y, border)
			elif y < 3 or y >= h - 3:
				img.set_pixel(x, y, border)
			else:
				img.set_pixel(x, y, fabric)

	# Center diamond emblem
	var cx: int = w / 2
	var cy: int = h / 2
	for x in range(w):
		for y in range(2, h - 2):
			var dx: int = absi(x - cx)
			var dy: int = absi(y - cy)
			if dx + dy <= 3:
				img.set_pixel(x, y, emblem)

	# Pennant bottom — pointed/ragged edge
	for x in range(1, w - 1):
		var dist_from_center: int = absi(x - cx)
		var depth: int = h - 2 - dist_from_center
		if depth < h - 2:
			for y in range(h - 2, mini(depth + 1, h)):
				img.set_pixel(x, y, Color(0, 0, 0, 0))
		# Keep center columns extending further
		if dist_from_center <= 1:
			for y in range(h - 2, h):
				img.set_pixel(x, y, fabric)

	return ImageTexture.create_from_image(img)

func _make_altar_texture() -> ImageTexture:
	var w: int = 20
	var h: int = 16
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)

	for y in range(h):
		# Trapezoidal shape: wider at bottom, narrower at top
		var t: float = float(y) / float(h)
		var half_width: float = lerpf(6.0, 9.0, t)
		var cx: float = w / 2.0

		for x in range(w):
			var dist: float = absf(float(x) - cx)
			if dist > half_width:
				continue

			var shade: float
			if y < 4:
				# Top platform — lighter
				shade = 0.5 - dist * 0.01
			elif y == 4 or y == 10:
				# Step ledges
				shade = 0.45
			else:
				shade = 0.4 - dist * 0.01

			# Edge darkening
			if dist > half_width - 1.5:
				shade *= 0.75

			var variation: float = fmod(absf(sin(float(x * 7 + y * 13))), 1.0) * 0.03
			img.set_pixel(x, y, Color(shade + variation, (shade + variation) * 0.95, (shade + variation) * 0.9, 1.0))

	return ImageTexture.create_from_image(img)

func _make_blood_stain_texture() -> ImageTexture:
	var w: int = 18
	var h: int = 12
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var cx: float = w / 2.0
	var cy: float = h / 2.0
	var max_radius: float = minf(cx, cy) - 1.0
	var hash_seed: float = randf() * TAU

	for x in range(w):
		for y in range(h):
			var dx: float = float(x) - cx
			var dy: float = float(y) - cy
			var dist: float = sqrt(dx * dx + dy * dy)
			var angle: float = atan2(dy, dx)
			# Organic irregular edge
			var edge_radius: float = max_radius * (0.6 + 0.4 * absf(sin(angle * 3.0 + hash_seed)))
			if dist < edge_radius:
				var t: float = dist / edge_radius
				var alpha: float = (1.0 - t * t) * 0.8
				img.set_pixel(x, y, Color(0.35, 0.08, 0.05, alpha))

	return ImageTexture.create_from_image(img)

func _make_skull_pile_texture() -> ImageTexture:
	var w: int = 16
	var h: int = 12
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var bone_color := Color(0.7, 0.68, 0.6, 0.8)
	var eye_color := Color(0.15, 0.1, 0.1, 0.9)

	# Draw 3 overlapping skull circles
	var skull_positions := [Vector2(5, 6), Vector2(10, 5), Vector2(7, 9)]
	var skull_radii := [3.5, 3.0, 3.2]

	for idx in range(skull_positions.size()):
		var sc: Vector2 = skull_positions[idx]
		var sr: float = skull_radii[idx]
		for x in range(w):
			for y in range(h):
				var dist: float = Vector2(x, y).distance_to(sc)
				if dist < sr:
					var shade: float = 1.0 - dist / sr * 0.3
					img.set_pixel(x, y, Color(bone_color.r * shade, bone_color.g * shade, bone_color.b * shade, bone_color.a))

		# Eye sockets — two small dark dots
		var eye_y: int = int(sc.y) - 1
		var left_eye_x: int = int(sc.x) - 1
		var right_eye_x: int = int(sc.x) + 1
		if left_eye_x >= 0 and left_eye_x < w and eye_y >= 0 and eye_y < h:
			img.set_pixel(left_eye_x, eye_y, eye_color)
		if right_eye_x >= 0 and right_eye_x < w and eye_y >= 0 and eye_y < h:
			img.set_pixel(right_eye_x, eye_y, eye_color)

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
