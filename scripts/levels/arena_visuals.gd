extends RefCounted

var _owner: Node2D

func _init(owner: Node2D) -> void:
	_owner = owner

func setup_vignette(palette: Dictionary, vignette_shader: Shader) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	_owner.add_child(layer)

	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.color = Color(1.0, 1.0, 1.0, 0.0)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = vignette_shader
	mat.set_shader_parameter("tint_color", palette["edge_outer"])
	rect.material = mat
	layer.add_child(rect)

func setup_low_health_overlay(low_health_shader: Shader) -> ShaderMaterial:
	var layer := CanvasLayer.new()
	layer.layer = 6
	_owner.add_child(layer)

	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.color = Color(1.0, 1.0, 1.0, 0.0)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = low_health_shader
	material.set_shader_parameter("health_ratio", 1.0)
	rect.material = material
	layer.add_child(rect)
	return material

func connect_low_health_overlay(material: ShaderMaterial, callback: Callable) -> void:
	await _owner.get_tree().process_frame
	var player: PlayerController = GameManager.get_player()
	if player and player.has_node("HealthComponent"):
		var health: HealthComponent = player.get_node("HealthComponent")
		if not health.health_changed.is_connected(callback):
			health.health_changed.connect(callback)
		callback.call(health.current_health, health.max_health)

func update_low_health_overlay(material: ShaderMaterial, current: float, maximum: float) -> void:
	if material:
		material.set_shader_parameter("health_ratio", current / maxf(maximum, 1.0))

func setup_lighting(palette: Dictionary) -> void:
	var canvas_mod := CanvasModulate.new()
	canvas_mod.color = palette["ambient_tint"]
	_owner.add_child(canvas_mod)

	await _owner.get_tree().process_frame
	var player: PlayerController = GameManager.get_player()
	if player:
		var light := PointLight2D.new()
		light.texture = _create_light_texture()
		light.color = palette["light_color"]
		light.energy = 1.2
		light.texture_scale = 3.5
		light.shadow_enabled = false
		light.name = "PlayerLight"
		player.add_child(light)

func spawn_ambient_particles(palette: Dictionary, floor_theme: int, arena_radius: float) -> void:
	var particle_layer := Node2D.new()
	particle_layer.z_index = -1
	particle_layer.name = "AmbientParticles"
	_owner.add_child(particle_layer)

	var accent: Color = palette["accent"]
	for _mote_index in range(15):
		var mote := Sprite2D.new()
		var size := randi_range(2, 4)
		var alpha := randf_range(0.08, 0.2)
		var col := accent.lightened(randf_range(-0.1, 0.2))
		col.a = alpha
		mote.texture = PlaceholderSprites.create_circle_texture(size, col)
		mote.position = Vector2(randf_range(-600, 600), randf_range(-400, 400))
		mote.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		particle_layer.add_child(mote)
		_animate_mote(mote, false, accent, arena_radius)

	for _edge_index in range(20):
		var edge_mote := Sprite2D.new()
		var edge_size := randi_range(2, 3)
		var edge_color := accent
		edge_color.a = randf_range(0.25, 0.5)
		edge_mote.texture = PlaceholderSprites.create_circle_texture(edge_size, edge_color)
		edge_mote.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		particle_layer.add_child(edge_mote)
		_animate_mote(edge_mote, true, accent, arena_radius)

	if floor_theme == 1 or floor_theme == 3:
		for _ash_index in range(12):
			var ash := Sprite2D.new()
			ash.texture = PlaceholderSprites.create_circle_texture(2, Color(0.25, 0.22, 0.2, 0.15))
			ash.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			particle_layer.add_child(ash)
			_animate_ash(ash)

func _animate_mote(mote: Sprite2D, is_edge: bool, accent: Color, arena_radius: float) -> void:
	if not is_instance_valid(mote) or not mote.is_inside_tree():
		return

	var duration := randf_range(3.0, 6.0)
	var start_pos: Vector2
	var drift: Vector2

	if is_edge:
		var angle: float = randf() * TAU
		var edge_r: float = arena_radius * randf_range(0.8, 1.0)
		start_pos = Vector2(cos(angle) * edge_r, sin(angle) * edge_r * 0.5)
		drift = Vector2(randf_range(-20, 20), randf_range(-50, -20))
	else:
		start_pos = Vector2(randf_range(-600, 600), randf_range(-400, 400))
		drift = Vector2(randf_range(-30, 30), randf_range(-40, -15))

	mote.position = start_pos
	mote.modulate.a = 0.0
	mote.modulate = accent if is_edge else mote.modulate

	var tween := mote.create_tween()
	tween.tween_property(mote, "modulate:a", 1.0, duration * 0.2)
	tween.tween_property(mote, "position", start_pos + drift, duration * 0.6)
	tween.tween_property(mote, "modulate:a", 0.0, duration * 0.2)
	tween.tween_callback(_animate_mote.bind(mote, is_edge, accent, arena_radius))

func _animate_ash(ash: Sprite2D) -> void:
	if not is_instance_valid(ash) or not ash.is_inside_tree():
		return

	var duration := randf_range(4.0, 8.0)
	var start_pos := Vector2(randf_range(-500, 500), randf_range(-400, -200))
	ash.position = start_pos
	ash.modulate.a = 0.0

	var tween := ash.create_tween()
	tween.tween_property(ash, "modulate:a", 1.0, duration * 0.15)
	tween.tween_property(ash, "position", start_pos + Vector2(randf_range(-40, 40), randf_range(150, 300)), duration * 0.7)
	tween.tween_property(ash, "modulate:a", 0.0, duration * 0.15)
	tween.tween_callback(_animate_ash.bind(ash))

func spawn_floor_decals(arena_radius: float) -> void:
	var decal_layer := Node2D.new()
	decal_layer.z_index = -2
	decal_layer.name = "FloorDecals"
	_owner.add_child(decal_layer)

	var max_dist: float = arena_radius * 0.8
	for _decal_index in range(12):
		var angle: float = randf() * TAU
		var dist: float = randf_range(40.0, max_dist)
		var pos := Vector2(cos(angle) * dist, sin(angle) * 0.5 * dist)
		var decal := Sprite2D.new()
		decal.texture = _make_crack_decal() if randf() < 0.5 else _make_scorch_decal()
		decal.position = pos
		decal.rotation = randf() * TAU
		decal.modulate.a = randf_range(0.08, 0.2)
		decal.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		decal_layer.add_child(decal)

func _create_light_texture() -> Texture2D:
	var size: int = 128
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size / 2.0, size / 2.0)
	for x in range(size):
		for y in range(size):
			var dist: float = Vector2(x, y).distance_to(center) / (size / 2.0)
			var alpha: float = clampf(1.0 - dist * dist, 0.0, 1.0)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(image)

func _make_crack_decal() -> ImageTexture:
	var size: int = 32
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0
	var cy: float = size / 2.0
	for _line_idx in range(randi_range(2, 3)):
		var angle: float = randf() * TAU
		var steps: int = randi_range(4, 7)
		var px: float = cx
		var py: float = cy
		for _step_index in range(steps):
			angle += randf_range(-0.6, 0.6)
			var step_len: float = randf_range(2.0, 5.0)
			var nx: float = px + cos(angle) * step_len
			var ny: float = py + sin(angle) * step_len
			for t in range(int(step_len) + 1):
				var lx: int = clampi(int(lerpf(px, nx, float(t) / maxf(step_len, 1.0))), 0, size - 1)
				var ly: int = clampi(int(lerpf(py, ny, float(t) / maxf(step_len, 1.0))), 0, size - 1)
				img.set_pixel(lx, ly, Color(0.2, 0.18, 0.15, 0.8))
			px = nx
			py = ny
	return ImageTexture.create_from_image(img)

func _make_scorch_decal() -> ImageTexture:
	var size: int = 24
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size / 2.0, size / 2.0)
	var radius: float = size / 2.0
	for x in range(size):
		for y in range(size):
			var dist: float = Vector2(x, y).distance_to(center)
			if dist < radius:
				var t: float = dist / radius
				var alpha: float = (1.0 - t * t) * 0.6
				img.set_pixel(x, y, Color(0.08, 0.06, 0.04, alpha))
	return ImageTexture.create_from_image(img)
