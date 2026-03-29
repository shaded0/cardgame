class_name ScreenFX
extends RefCounted

## Screen-wide effects: camera shake, hit freeze, flash overlays.
## All methods are static for easy access from anywhere.

static func shake(node: Node, intensity: float = 8.0, duration: float = 0.15) -> void:
	## Shake the camera by temporarily offsetting it. Finds the active Camera2D automatically.
	if node == null or not is_instance_valid(node):
		return
	var camera := node.get_viewport().get_camera_2d()
	if camera == null:
		return

	# Keep only one active shake tween per camera to avoid tween pileups during dense combat.
	var existing_tween = camera.get_meta("_screenfx_shake_tween", null) as Tween
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
	Engine.time_scale = 0.05
	await tree.create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

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
