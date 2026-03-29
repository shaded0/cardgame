class_name SpellEffectVisual
extends Node2D

## Visual flash/burst for card spell effects.

static func spawn_burst(parent: Node, pos: Vector2, radius: float, color: Color, duration: float = 0.3) -> void:
	var effect := SpellEffectVisual.new()
	effect.global_position = pos
	effect.z_index = 5

	var sprite := Sprite2D.new()
	sprite.texture = PlaceholderSprites.create_circle_texture(int(radius), color)
	sprite.modulate.a = 0.7
	effect.add_child(sprite)

	parent.add_child(effect)

	var tween: Tween = effect.create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), duration).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate:a", 0.0, duration)
	tween.chain().tween_callback(effect.queue_free)

static func spawn_slash(parent: Node, pos: Vector2, direction: Vector2, color: Color) -> void:
	var effect := SpellEffectVisual.new()
	effect.global_position = pos
	effect.z_index = 5

	# Create a slash line
	var line := Line2D.new()
	var perp := Vector2(-direction.y, direction.x) * 36.0
	line.add_point(-perp)
	line.add_point(perp)
	line.width = 3.0
	line.default_color = color
	effect.add_child(line)

	parent.add_child(effect)

	var tween: Tween = effect.create_tween()
	tween.set_parallel(true)
	tween.tween_property(line, "modulate:a", 0.0, 0.2)
	tween.tween_property(effect, "position", effect.position + direction * 24.0, 0.2)
	tween.chain().tween_callback(effect.queue_free)

static func spawn_heal(parent: Node, pos: Vector2) -> void:
	var effect := SpellEffectVisual.new()
	effect.global_position = pos
	effect.z_index = 5

	# Green plus sign
	var h_line := Line2D.new()
	h_line.add_point(Vector2(-15, 0))
	h_line.add_point(Vector2(15, 0))
	h_line.width = 2.0
	h_line.default_color = Color(0.3, 1.0, 0.3, 0.9)
	effect.add_child(h_line)

	var v_line := Line2D.new()
	v_line.add_point(Vector2(0, -15))
	v_line.add_point(Vector2(0, 15))
	v_line.width = 2.0
	v_line.default_color = Color(0.3, 1.0, 0.3, 0.9)
	effect.add_child(v_line)

	parent.add_child(effect)

	var tween: Tween = effect.create_tween()
	tween.set_parallel(true)
	tween.tween_property(effect, "position:y", effect.position.y - 12.0, 0.5).set_ease(Tween.EASE_OUT)
	tween.tween_property(effect, "modulate:a", 0.0, 0.5).set_delay(0.15)
	tween.chain().tween_callback(effect.queue_free)

static func spawn_shield(parent: Node, pos: Vector2, color: Color = Color(0.4, 0.6, 1.0, 0.5)) -> void:
	var effect := SpellEffectVisual.new()
	effect.global_position = pos
	effect.z_index = 4

	var sprite := Sprite2D.new()
	sprite.texture = PlaceholderSprites.create_circle_texture(42, color)
	sprite.modulate.a = 0.0
	effect.add_child(sprite)

	parent.add_child(effect)

	# Fade in then fade out
	var tween: Tween = effect.create_tween()
	tween.tween_property(sprite, "modulate:a", 0.5, 0.15)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.8)
	tween.tween_callback(effect.queue_free)

static func spawn_mana_gain(parent: Node, pos: Vector2) -> void:
	var effect := SpellEffectVisual.new()
	effect.global_position = pos + Vector2(0, -24)
	effect.z_index = 5

	# Small blue sparkles rising
	for i in range(3):
		var dot := Sprite2D.new()
		dot.texture = PlaceholderSprites.create_circle_texture(6, Color(0.3, 0.5, 1.0, 0.8))
		dot.position = Vector2(randf_range(-18, 18), randf_range(-6, 6))
		effect.add_child(dot)

	parent.add_child(effect)

	var tween: Tween = effect.create_tween()
	tween.set_parallel(true)
	tween.tween_property(effect, "position:y", effect.position.y - 45.0, 0.4).set_ease(Tween.EASE_OUT)
	tween.tween_property(effect, "modulate:a", 0.0, 0.4).set_delay(0.1)
	tween.chain().tween_callback(effect.queue_free)
