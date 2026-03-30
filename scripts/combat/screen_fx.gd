class_name ScreenFX
extends RefCounted

## Screen-wide effects: camera shake, hit freeze, flash overlays.
## All methods are static for easy access from anywhere.

static var _hit_freeze_depth: int = 0
static var _hit_freeze_restore_scale: float = 1.0

static func shake(node: Node, intensity: float = 8.0, duration: float = 0.15) -> void:
	## Shake the camera by temporarily offsetting it. Finds the active Camera2D automatically.
	if node == null or not is_instance_valid(node):
		return
	var camera := node.get_viewport().get_camera_2d()
	if camera == null:
		return

	# Keep only one active shake tween per camera to avoid tween pileups during dense combat.
	var existing_tween: Tween = null
	if camera.has_meta("_screenfx_shake_tween"):
		existing_tween = camera.get_meta("_screenfx_shake_tween") as Tween
	if existing_tween and existing_tween.is_valid():
		existing_tween.kill()

	var tween := node.create_tween()
	camera.set_meta("_screenfx_shake_tween", tween)
	var steps := maxi(int(duration / 0.02), 1)
	for i in range(steps):
		var t_ratio := 1.0 - float(i) / float(steps)
		var offset := Vector2(
			randf_range(-intensity, intensity) * t_ratio,
			randf_range(-intensity, intensity) * t_ratio
		)
		tween.tween_property(camera, "offset", offset, 0.02)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.02)
	tween.finished.connect(func() -> void:
		if is_instance_valid(camera):
			camera.set_meta("_screenfx_shake_tween", null)
	)

static func hit_freeze(tree: SceneTree, duration: float = 0.05) -> void:
	## Brief engine pause for impact weight (hit stop).
	if tree == null:
		return
	if _hit_freeze_depth == 0:
		_hit_freeze_restore_scale = Engine.time_scale
		Engine.time_scale = minf(Engine.time_scale, 0.05)
	_hit_freeze_depth += 1
	await tree.create_timer(duration, true, false, true).timeout
	_hit_freeze_depth = maxi(_hit_freeze_depth - 1, 0)
	if _hit_freeze_depth == 0:
		Engine.time_scale = _hit_freeze_restore_scale

static func spawn_hit_sparks(parent: Node, pos: Vector2, count: int = 6, color: Color = Color(1.0, 0.8, 0.3)) -> void:
	## Burst of small directional sparks on hit.
	if parent == null or not is_instance_valid(parent):
		return

	var clamped_count := mini(count, 8)
	for i in range(clamped_count):
		var spark := Line2D.new()
		spark.z_index = 6
		spark.width = 2.0
		spark.default_color = color

		var angle := randf() * TAU
		var length := randf_range(8.0, 20.0)
		var dir := Vector2(cos(angle), sin(angle))
		spark.add_point(Vector2.ZERO)
		spark.add_point(dir * length)
		spark.global_position = pos

		parent.add_child(spark)

		var tween := spark.create_tween().set_parallel(true)
		tween.tween_property(spark, "position", spark.position + dir * randf_range(15.0, 35.0), 0.2)
		tween.tween_property(spark, "modulate:a", 0.0, 0.2)
		tween.chain().tween_callback(spark.queue_free)

static func spawn_ground_crack(parent: Node, pos: Vector2, radius: float = 20.0) -> void:
	## Dark crack lines radiating from impact point.
	var crack_node := Node2D.new()
	crack_node.global_position = pos
	crack_node.z_index = -1

	for i in range(4):
		var line := Line2D.new()
		line.default_color = Color(0.1, 0.08, 0.06, 0.6)
		line.width = 1.5

		var angle := randf() * TAU
		var segments := randi_range(2, 4)
		var current := Vector2.ZERO
		line.add_point(current)
		for _s in range(segments):
			angle += randf_range(-0.5, 0.5)
			var step := randf_range(radius * 0.3, radius * 0.7)
			current += Vector2(cos(angle), sin(angle)) * step
			line.add_point(current)
		crack_node.add_child(line)

	parent.add_child(crack_node)

	# Fade out cracks
	var tween := crack_node.create_tween()
	tween.tween_property(crack_node, "modulate:a", 0.0, 1.5).set_delay(0.5)
	tween.tween_callback(crack_node.queue_free)

static func flash(node: Node, color: Color = Color(1, 1, 1, 0.6), duration: float = 0.12) -> void:
	## Full-screen color flash (white for big hits, red for player damage, etc).
	if node == null or not is_instance_valid(node):
		return
	var viewport := node.get_viewport()
	if viewport == null:
		return

	var layer := CanvasLayer.new()
	layer.layer = 8
	node.get_tree().root.add_child(layer)

	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)

	var tween := rect.create_tween()
	tween.tween_property(rect, "color:a", 0.0, duration).set_ease(Tween.EASE_IN)
	tween.tween_callback(layer.queue_free)

static func spawn_impact_ring(parent: Node, pos: Vector2, color: Color = Color(1.0, 0.9, 0.6, 0.7), max_radius: float = 30.0) -> void:
	## Expanding shockwave ring at impact point.
	if parent == null or not is_instance_valid(parent):
		return

	var ring := Node2D.new()
	ring.global_position = pos
	ring.z_index = 5
	parent.add_child(ring)

	# Draw ring using a script-less approach: use Line2D as a circle
	var segments := 24
	var line := Line2D.new()
	line.width = 2.5
	line.default_color = color
	for i in range(segments + 1):
		var angle: float = TAU * float(i) / float(segments)
		line.add_point(Vector2(cos(angle), sin(angle)) * 4.0)
	ring.add_child(line)

	var tween := ring.create_tween().set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(max_radius / 4.0, max_radius / 4.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(ring, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(ring.queue_free)

static func spawn_dust_puff(parent: Node, pos: Vector2, direction: Vector2 = Vector2.ZERO, count: int = 3) -> void:
	## Small ground dust kicked up on movement start, stop, or direction change.
	## Direction biases particles opposite to movement (dust trails behind).
	if parent == null or not is_instance_valid(parent):
		return

	var kick_dir: Vector2 = -direction if direction.length() > 0.1 else Vector2.UP
	for i in range(count):
		var puff := Sprite2D.new()
		puff.texture = PlaceholderSprites.create_circle_texture(randi_range(2, 4), Color(0.6, 0.55, 0.45, 0.4))
		puff.global_position = pos + Vector2(randf_range(-6, 6), randf_range(0, 4))
		puff.z_index = -1
		parent.add_child(puff)

		var spread := kick_dir.rotated(randf_range(-0.6, 0.6)) * randf_range(8.0, 18.0)
		var tween := puff.create_tween().set_parallel(true)
		tween.tween_property(puff, "position", puff.position + spread, randf_range(0.2, 0.35))
		tween.tween_property(puff, "modulate:a", 0.0, 0.3).set_delay(0.05)
		tween.tween_property(puff, "scale", Vector2(1.5, 1.5), 0.35)
		tween.chain().tween_callback(puff.queue_free)

static func spawn_smoke_puff(parent: Node, pos: Vector2, count: int = 3) -> void:
	## Small smoke particles drifting upward.
	if parent == null or not is_instance_valid(parent):
		return

	for i in range(count):
		var puff := Sprite2D.new()
		puff.texture = PlaceholderSprites.create_circle_texture(randi_range(3, 6), Color(0.3, 0.3, 0.35, 0.5))
		puff.global_position = pos + Vector2(randf_range(-10, 10), randf_range(-5, 5))
		puff.z_index = 5
		parent.add_child(puff)

		var tween := puff.create_tween().set_parallel(true)
		tween.tween_property(puff, "position:y", puff.position.y - randf_range(20, 40), randf_range(0.4, 0.7))
		tween.tween_property(puff, "position:x", puff.position.x + randf_range(-15, 15), randf_range(0.4, 0.7))
		tween.tween_property(puff, "modulate:a", 0.0, 0.5).set_delay(0.15)
		tween.tween_property(puff, "scale", Vector2(1.8, 1.8), 0.6)
		tween.chain().tween_callback(puff.queue_free)
