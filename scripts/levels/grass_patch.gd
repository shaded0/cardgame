class_name GrassPatch
extends Node2D

## Decorative grass tufts that sway when entities walk through them.
## Place via ArenaBase._add_grass_cluster() for organic environment feel.

var _blades: Array[Sprite2D] = []
var _original_rotations: Array[float] = []
var _detection_area: Area2D

const SWAY_RECOVER_SPEED: float = 4.0
const SWAY_AMOUNT: float = 0.5  ## radians

func setup(pos: Vector2, blade_count: int = 4) -> void:
	global_position = pos
	z_index = -1

	for i in range(blade_count):
		var blade := Sprite2D.new()
		blade.texture = _make_blade_texture()
		blade.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		# Scatter blades within a small area
		blade.position = Vector2(randf_range(-10, 10), randf_range(-6, 6))
		blade.offset = Vector2(0, -8)  # Anchor at base
		blade.rotation = randf_range(-0.15, 0.15)
		add_child(blade)
		_blades.append(blade)
		_original_rotations.append(blade.rotation)

	# Gentle idle sway
	_start_idle_sway()

	# Detection area for walk-through reaction
	_detection_area = Area2D.new()
	_detection_area.collision_layer = 0
	_detection_area.collision_mask = 1 | 2  # Detect player and enemies
	var col := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18.0
	col.shape = circle
	_detection_area.add_child(col)
	_detection_area.body_entered.connect(_on_entity_entered)
	add_child(_detection_area)

func _on_entity_entered(body: Node2D) -> void:
	## Sway blades away from the entity passing through.
	if body is CharacterBody2D:
		var push_dir: float = sign(body.global_position.x - global_position.x)
		if absf(push_dir) < 0.1:
			push_dir = 1.0 if randf() > 0.5 else -1.0

		for i in range(_blades.size()):
			var blade := _blades[i]
			if not is_instance_valid(blade):
				continue
			var sway_angle: float = -push_dir * SWAY_AMOUNT * randf_range(0.7, 1.3)
			var tween := blade.create_tween()
			tween.tween_property(blade, "rotation", _original_rotations[i] + sway_angle, 0.08)
			tween.tween_property(blade, "rotation", _original_rotations[i] - sway_angle * 0.3, 0.12)
			tween.tween_property(blade, "rotation", _original_rotations[i], 0.2).set_ease(Tween.EASE_OUT)

		# Small leaf particles
		var parent := get_parent()
		if parent:
			for j in range(2):
				var leaf := Sprite2D.new()
				leaf.texture = PlaceholderSprites.create_circle_texture(2, Color(0.25, 0.5, 0.2, 0.5))
				leaf.global_position = global_position + Vector2(randf_range(-8, 8), randf_range(-4, 4))
				leaf.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				leaf.z_index = 2
				parent.add_child(leaf)
				var tween := leaf.create_tween().set_parallel(true)
				tween.tween_property(leaf, "position", leaf.position + Vector2(randf_range(-20, 20), randf_range(-25, -10)), 0.4)
				tween.tween_property(leaf, "modulate:a", 0.0, 0.35).set_delay(0.1)
				tween.chain().tween_callback(leaf.queue_free)

func _start_idle_sway() -> void:
	## Gentle ambient wind sway so grass doesn't look static.
	for i in range(_blades.size()):
		var blade := _blades[i]
		if not is_instance_valid(blade):
			continue
		# Stagger start times so blades don't sway in unison
		var delay := randf_range(0.0, 2.0)
		_animate_blade_sway(blade, i, delay)

func _animate_blade_sway(blade: Sprite2D, index: int, initial_delay: float = 0.0) -> void:
	if not is_instance_valid(blade) or not blade.is_inside_tree():
		return
	var base_rot: float = _original_rotations[index]
	var sway := randf_range(0.06, 0.12)
	var duration := randf_range(1.5, 2.5)

	var tween := blade.create_tween()
	if initial_delay > 0.0:
		tween.tween_interval(initial_delay)
	tween.tween_property(blade, "rotation", base_rot + sway, duration * 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(blade, "rotation", base_rot - sway, duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(blade, "rotation", base_rot, duration * 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(_animate_blade_sway.bind(blade, index, 0.0))

func _make_blade_texture() -> ImageTexture:
	var w: int = 4
	var h: int = 14
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		var t: float = float(y) / float(h)
		# Narrower at top, wider at base
		var half_width: float = lerpf(0.3, 1.5, t)
		var green: float = lerpf(0.55, 0.3, t)  # Lighter at tip
		for x in range(w):
			var cx: float = float(x) - w / 2.0
			if absf(cx) < half_width:
				img.set_pixel(x, y, Color(0.15, green, 0.12, 0.85))
	return ImageTexture.create_from_image(img)
