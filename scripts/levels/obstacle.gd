class_name Obstacle
extends StaticBody2D

## Arena obstacle — blocks movement and projectiles.
## Crates are destructible; pillars/walls react to hits but don't break.
## Call setup() after instancing to set type and size.

enum ObstacleType { PILLAR, WALL_H, WALL_V, CRATE }

var obstacle_type: ObstacleType = ObstacleType.PILLAR
var _sprite: Sprite2D
var _shadow: Sprite2D

## Destructible support (crates only)
var destructible: bool = false
var health: float = 40.0
var _dead: bool = false

func setup(type: ObstacleType, pos: Vector2) -> void:
	obstacle_type = type
	global_position = pos
	destructible = type == ObstacleType.CRATE

	# Collision layers: block player (1), enemies (2), player projectiles (4), enemy projectiles (64)
	collision_layer = 1 | 2
	collision_mask = 0

	var shape := CollisionShape2D.new()
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	match type:
		ObstacleType.PILLAR:
			var rect := RectangleShape2D.new()
			rect.size = Vector2(32, 24)
			shape.shape = rect
			_sprite.texture = _make_pillar_texture()
			_sprite.offset = Vector2(0, -16)
		ObstacleType.WALL_H:
			var rect := RectangleShape2D.new()
			rect.size = Vector2(96, 20)
			shape.shape = rect
			_sprite.texture = _make_wall_texture(96, 32)
			_sprite.offset = Vector2(0, -10)
		ObstacleType.WALL_V:
			var rect := RectangleShape2D.new()
			rect.size = Vector2(20, 96)
			shape.shape = rect
			_sprite.texture = _make_wall_texture(20, 96)
			_sprite.offset = Vector2(0, -10)
		ObstacleType.CRATE:
			var rect := RectangleShape2D.new()
			rect.size = Vector2(40, 30)
			shape.shape = rect
			_sprite.texture = _make_crate_texture()
			_sprite.offset = Vector2(0, -12)

	add_child(shape)
	add_child(_sprite)

	# Drop shadow beneath obstacle
	_shadow = Sprite2D.new()
	var shadow_w: int = int(shape.shape.size.x * 1.2)
	var shadow_h: int = int(shape.shape.size.y * 0.6)
	_shadow.texture = PlaceholderSprites.create_shadow_texture(maxi(shadow_w, 8), maxi(shadow_h, 6))
	_shadow.offset = Vector2(0, 4)
	_shadow.z_index = -2
	_shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_shadow)

	# Area2D detector to block projectiles on contact.
	var blocker := Area2D.new()
	blocker.collision_layer = 0  # Not a body — pure detector
	blocker.collision_mask = 4 | 64  # Detect player and enemy projectiles
	var blocker_shape := CollisionShape2D.new()
	blocker_shape.shape = shape.shape.duplicate()
	blocker.add_child(blocker_shape)
	blocker.area_entered.connect(_on_projectile_hit)
	add_child(blocker)

	# Hurtbox so melee attacks can interact with obstacles
	var hurtbox := Hurtbox.new()
	hurtbox.iframes_duration = 0.0  # No i-frames on environment objects
	hurtbox.collision_layer = 2  # Enemies layer so player hitbox (mask 2) detects it
	hurtbox.collision_mask = 0
	var hurtbox_shape := CollisionShape2D.new()
	hurtbox_shape.shape = shape.shape.duplicate()
	hurtbox.add_child(hurtbox_shape)
	hurtbox.received_hit.connect(_on_melee_hit)
	add_child(hurtbox)

func _on_projectile_hit(area: Area2D) -> void:
	if area is Hurtbox:
		return  # It's a hurtbox, not a projectile
	_react_to_hit(area.global_position)

	if destructible:
		# Guess damage from projectile if it has a damage property
		var proj_damage: float = area.get("damage") if area.get("damage") != null else 15.0
		_take_damage(proj_damage, area.global_position)

	area.queue_free()

func _on_melee_hit(hitbox: Hitbox) -> void:
	_react_to_hit(hitbox.global_position)
	if destructible:
		_take_damage(hitbox.damage, hitbox.global_position)

func _react_to_hit(hit_source_pos: Vector2) -> void:
	## Visual feedback on any obstacle when hit — shake + sparks.
	if _dead:
		return
	var parent := get_parent()
	if parent == null:
		return

	# Small sparks at impact point
	var hit_dir: Vector2 = (global_position - hit_source_pos).normalized()
	var spark_pos: Vector2 = global_position + hit_dir * -10.0
	ScreenFX.spawn_hit_sparks(parent, spark_pos, 3, Color(0.7, 0.65, 0.5))

	# Shake the sprite
	if is_instance_valid(_sprite):
		var original_offset: Vector2 = _sprite.offset
		var tween := create_tween()
		tween.tween_property(_sprite, "offset", original_offset + Vector2(randf_range(-3, 3), randf_range(-2, 2)), 0.03)
		tween.tween_property(_sprite, "offset", original_offset + Vector2(randf_range(-2, 2), randf_range(-1, 1)), 0.03)
		tween.tween_property(_sprite, "offset", original_offset, 0.04)

func _take_damage(amount: float, hit_source_pos: Vector2) -> void:
	if _dead:
		return
	health -= amount
	# Flash white on damage
	if is_instance_valid(_sprite):
		_sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)
		var flash_tween := create_tween()
		flash_tween.tween_property(_sprite, "modulate", Color(1, 1, 1, 1), 0.1)

	if health <= 0.0:
		_shatter(hit_source_pos)

func _shatter(hit_source_pos: Vector2) -> void:
	_dead = true
	var parent := get_parent()
	if parent == null:
		queue_free()
		return

	var shatter_pos: Vector2 = global_position
	var hit_dir: Vector2 = (shatter_pos - hit_source_pos).normalized()

	# Screen shake for satisfying destruction
	ScreenFX.shake(self, 4.0, 0.1)

	# Spawn debris chunks flying outward
	for i in range(randi_range(5, 8)):
		var chunk := Sprite2D.new()
		var size := randi_range(3, 7)
		var shade := randf_range(0.3, 0.55)
		chunk.texture = PlaceholderSprites.create_rect_texture(size, size, Color(shade, shade * 0.75, shade * 0.4, 1.0))
		chunk.global_position = shatter_pos + Vector2(randf_range(-12, 12), randf_range(-8, 8))
		chunk.z_index = 3
		chunk.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		parent.add_child(chunk)

		var angle: float = hit_dir.angle() + randf_range(-1.2, 1.2)
		var speed := randf_range(60.0, 160.0)
		var fly_dir := Vector2(cos(angle), sin(angle))
		var tween := chunk.create_tween().set_parallel(true)
		tween.tween_property(chunk, "position", chunk.position + fly_dir * speed * 0.3, 0.35).set_ease(Tween.EASE_OUT)
		tween.tween_property(chunk, "rotation", randf_range(-4.0, 4.0), 0.35)
		tween.tween_property(chunk, "modulate:a", 0.0, 0.25).set_delay(0.15)
		tween.chain().tween_callback(chunk.queue_free)

	# Dust cloud
	ScreenFX.spawn_dust_puff(parent, shatter_pos, hit_dir, 5)

	# Spawn pickups
	_spawn_drops(parent, shatter_pos)

	queue_free()

func _spawn_drops(parent: Node, pos: Vector2) -> void:
	## Chance to drop health or mana pickups from destroyed crates.
	var drop_count := randi_range(1, 3)
	for i in range(drop_count):
		var is_health: bool = randf() < 0.4  # 40% health, 60% mana
		var pickup := Pickup.new()
		pickup.setup(Pickup.PickupType.HEALTH if is_health else Pickup.PickupType.MANA, pos)
		parent.add_child(pickup)

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
