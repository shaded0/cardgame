class_name SpellEffectVisual
extends Node2D

## Visual flash/burst for card spell effects.
## Enhanced with particles, trails, and screen effects for maximum juice.

## Cached light gradient texture shared by all transient lights.
static var _light_texture: Texture2D = null

static func _get_light_texture() -> Texture2D:
	if _light_texture:
		return _light_texture
	var size: int = 64
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size / 2.0, size / 2.0)
	for x in range(size):
		for y in range(size):
			var dist: float = Vector2(x, y).distance_to(center) / (size / 2.0)
			var alpha: float = clampf(1.0 - dist * dist, 0.0, 1.0)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	_light_texture = ImageTexture.create_from_image(image)
	return _light_texture

static func _attach_transient_light(node: Node2D, color: Color, energy: float = 0.8, light_scale: float = 1.5, duration: float = 0.3) -> void:
	## Add a brief PointLight2D that fades out and self-destructs.
	var light := PointLight2D.new()
	light.texture = _get_light_texture()
	light.color = color
	light.energy = energy
	light.texture_scale = light_scale
	light.shadow_enabled = false
	node.add_child(light)
	var tween := light.create_tween()
	tween.tween_property(light, "energy", 0.0, duration).set_ease(Tween.EASE_IN)
	tween.tween_callback(light.queue_free)

static func spawn_burst(parent: Node, pos: Vector2, radius: float, color: Color, duration: float = 0.3) -> void:
	var effect := SpellEffectVisual.new()
	effect.global_position = pos
	effect.z_index = 5

	# Main expanding ring
	var sprite := Sprite2D.new()
	sprite.texture = PlaceholderSprites.create_circle_texture(int(radius), color)
	sprite.modulate.a = 0.7
	effect.add_child(sprite)

	# Inner bright core
	var core := Sprite2D.new()
	core.texture = PlaceholderSprites.create_circle_texture(int(radius * 0.4), Color(1.0, 1.0, 1.0, 0.5))
	effect.add_child(core)

	parent.add_child(effect)

	var tween: Tween = effect.create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(2.0, 2.0), duration).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate:a", 0.0, duration)
	tween.tween_property(core, "scale", Vector2(1.5, 1.5), duration * 0.6).set_ease(Tween.EASE_OUT)
	tween.tween_property(core, "modulate:a", 0.0, duration * 0.6)
	tween.chain().tween_callback(effect.queue_free)

	# Transient light for the burst
	_attach_transient_light(effect, color.lightened(0.3), 1.0, 2.0, duration)

	# Spawn sparks around the burst
	ScreenFX.spawn_hit_sparks(parent, pos, 8, color.lightened(0.3))

static func spawn_slash(parent: Node, pos: Vector2, direction: Vector2, color: Color) -> void:
	var effect := SpellEffectVisual.new()
	effect.global_position = pos
	effect.z_index = 5

	# Main slash arc (two lines for thickness)
	var perp := Vector2(-direction.y, direction.x) * 40.0
	for i in range(2):
		var line := Line2D.new()
		var offset_perp := perp * (1.0 + i * 0.15)
		line.add_point(-offset_perp)
		line.add_point(offset_perp)
		line.width = 3.0 - i
		line.default_color = color if i == 0 else color.lightened(0.4)
		effect.add_child(line)

	# Trail particles along the slash
	for j in range(5):
		var t := float(j) / 4.0
		var trail_pos := perp.lerp(-perp, t)
		var dot := Sprite2D.new()
		dot.texture = PlaceholderSprites.create_circle_texture(4, color.lightened(0.2))
		dot.position = trail_pos + Vector2(randf_range(-5, 5), randf_range(-5, 5))
		dot.modulate.a = 0.7
		effect.add_child(dot)

	parent.add_child(effect)

	var tween: Tween = effect.create_tween()
	tween.set_parallel(true)
	tween.tween_property(effect, "modulate:a", 0.0, 0.25)
	tween.tween_property(effect, "position", effect.position + direction * 28.0, 0.25)
	tween.chain().tween_callback(effect.queue_free)

	# Sparks at the slash impact
	ScreenFX.spawn_hit_sparks(parent, pos, 4, color)

static func spawn_heal(parent: Node, pos: Vector2) -> void:
	var effect := SpellEffectVisual.new()
	effect.global_position = pos
	effect.z_index = 5

	var heal_color := Color(0.3, 1.0, 0.3, 0.9)

	# Plus sign
	var h_line := Line2D.new()
	h_line.add_point(Vector2(-15, 0))
	h_line.add_point(Vector2(15, 0))
	h_line.width = 3.0
	h_line.default_color = heal_color
	effect.add_child(h_line)

	var v_line := Line2D.new()
	v_line.add_point(Vector2(0, -15))
	v_line.add_point(Vector2(0, 15))
	v_line.width = 3.0
	v_line.default_color = heal_color
	effect.add_child(v_line)

	# Rising green sparkles
	for i in range(6):
		var sparkle := Sprite2D.new()
		sparkle.texture = PlaceholderSprites.create_circle_texture(3, Color(0.5, 1.0, 0.5, 0.7))
		sparkle.position = Vector2(randf_range(-20, 20), randf_range(-5, 5))
		effect.add_child(sparkle)

	parent.add_child(effect)

	# Green heal glow
	_attach_transient_light(effect, Color(0.3, 1.0, 0.3), 0.8, 1.5, 0.6)

	var tween: Tween = effect.create_tween()
	tween.set_parallel(true)
	tween.tween_property(effect, "position:y", effect.position.y - 20.0, 0.6).set_ease(Tween.EASE_OUT)
	tween.tween_property(effect, "modulate:a", 0.0, 0.6).set_delay(0.2)
	# Scale up gently
	tween.tween_property(effect, "scale", Vector2(1.3, 1.3), 0.3).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(effect.queue_free)

static func spawn_shield(parent: Node, pos: Vector2, color: Color = Color(0.4, 0.6, 1.0, 0.5)) -> void:
	var effect := SpellEffectVisual.new()
	effect.global_position = pos
	effect.z_index = 4

	# Outer shield ring
	var sprite := Sprite2D.new()
	sprite.texture = PlaceholderSprites.create_circle_texture(42, color)
	sprite.modulate.a = 0.0
	effect.add_child(sprite)

	# Inner shield glow
	var inner := Sprite2D.new()
	inner.texture = PlaceholderSprites.create_circle_texture(28, Color(0.6, 0.8, 1.0, 0.3))
	inner.modulate.a = 0.0
	effect.add_child(inner)

	parent.add_child(effect)

	var tween: Tween = effect.create_tween()
	tween.set_parallel(true)
	# Fade in
	tween.tween_property(sprite, "modulate:a", 0.5, 0.15)
	tween.tween_property(inner, "modulate:a", 0.4, 0.15)
	# Pulse scale
	tween.tween_property(sprite, "scale", Vector2(1.15, 1.15), 0.2).set_ease(Tween.EASE_OUT)
	tween.chain()
	# Hold then fade
	tween.tween_property(sprite, "modulate:a", 0.0, 0.6)
	tween.tween_property(inner, "modulate:a", 0.0, 0.6)
	tween.tween_callback(effect.queue_free)

static func spawn_mana_gain(parent: Node, pos: Vector2) -> void:
	var effect := SpellEffectVisual.new()
	effect.global_position = pos + Vector2(0, -24)
	effect.z_index = 5

	# More sparkles with varied sizes
	for i in range(6):
		var dot := Sprite2D.new()
		var r := randi_range(4, 8)
		dot.texture = PlaceholderSprites.create_circle_texture(r, Color(0.3, 0.5, 1.0, 0.8))
		dot.position = Vector2(randf_range(-22, 22), randf_range(-8, 8))
		effect.add_child(dot)

	parent.add_child(effect)

	var tween: Tween = effect.create_tween()
	tween.set_parallel(true)
	tween.tween_property(effect, "position:y", effect.position.y - 50.0, 0.5).set_ease(Tween.EASE_OUT)
	tween.tween_property(effect, "modulate:a", 0.0, 0.5).set_delay(0.1)
	# Spiral outward slightly
	tween.tween_property(effect, "scale", Vector2(1.4, 1.4), 0.5)
	tween.chain().tween_callback(effect.queue_free)

static func spawn_fire_explosion(parent: Node, pos: Vector2, radius: float = 30.0) -> void:
	## Big fiery explosion for AOE spells like Fireball.
	var effect := SpellEffectVisual.new()
	effect.global_position = pos
	effect.z_index = 5

	# Core explosion
	var core := Sprite2D.new()
	core.texture = PlaceholderSprites.create_circle_texture(int(radius * 0.5), Color(1.0, 0.9, 0.6, 0.9))
	effect.add_child(core)

	# Mid layer - orange
	var mid := Sprite2D.new()
	mid.texture = PlaceholderSprites.create_circle_texture(int(radius * 0.8), Color(1.0, 0.5, 0.1, 0.6))
	effect.add_child(mid)

	# Outer layer - dark red
	var outer := Sprite2D.new()
	outer.texture = PlaceholderSprites.create_circle_texture(int(radius), Color(0.6, 0.1, 0.0, 0.4))
	effect.add_child(outer)

	parent.add_child(effect)

	var tween: Tween = effect.create_tween()
	tween.set_parallel(true)
	# Expand outward
	tween.tween_property(outer, "scale", Vector2(2.5, 2.5), 0.4).set_ease(Tween.EASE_OUT)
	tween.tween_property(mid, "scale", Vector2(2.0, 2.0), 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_property(core, "scale", Vector2(1.5, 1.5), 0.2).set_ease(Tween.EASE_OUT)
	# Fade
	tween.tween_property(outer, "modulate:a", 0.0, 0.5)
	tween.tween_property(mid, "modulate:a", 0.0, 0.4)
	tween.tween_property(core, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(effect.queue_free)

	# Bright fire light
	_attach_transient_light(effect, Color(1.0, 0.5, 0.1), 1.5, 3.0, 0.5)

	# Lots of sparks + ground cracks
	ScreenFX.spawn_hit_sparks(parent, pos, 12, Color(1.0, 0.6, 0.2))
	ScreenFX.spawn_ground_crack(parent, pos, radius)

	# Screen shake for explosions
	ScreenFX.shake(parent, 12.0, 0.25)
