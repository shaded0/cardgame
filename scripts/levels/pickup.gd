class_name Pickup
extends Area2D

## Small collectible that flies out of broken crates and homes toward the player.
## Health pickups restore a small amount; mana pickups give a mana chunk.

enum PickupType { HEALTH, MANA }

var pickup_type: PickupType = PickupType.HEALTH
var _launched: bool = false
var _homing: bool = false
var _collected: bool = false
var _launch_velocity: Vector2 = Vector2.ZERO
var _sprite: Sprite2D

const LAUNCH_DURATION: float = 0.35
const HOME_SPEED: float = 500.0
const HOME_DELAY: float = 0.4
const PICKUP_RADIUS: float = 20.0
const HEALTH_AMOUNT: float = 5.0
const MANA_AMOUNT: float = 8.0

func setup(type: PickupType, pos: Vector2) -> void:
	pickup_type = type
	global_position = pos

	# Launch in a random arc away from origin
	var angle: float = randf() * TAU
	var speed: float = randf_range(80.0, 150.0)
	_launch_velocity = Vector2(cos(angle), sin(angle)) * speed

func _ready() -> void:
	# Visual
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	match pickup_type:
		PickupType.HEALTH:
			_sprite.texture = PlaceholderSprites.create_circle_texture(4, Color(0.3, 1.0, 0.4, 0.9))
		PickupType.MANA:
			_sprite.texture = PlaceholderSprites.create_circle_texture(4, Color(0.4, 0.5, 1.0, 0.9))
	add_child(_sprite)

	# Collision — detect player only
	collision_layer = 0
	collision_mask = 1  # Player layer
	var col := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = PICKUP_RADIUS
	col.shape = circle
	add_child(col)

	area_entered.connect(_on_collected)
	body_entered.connect(_on_body_collected)

	# Pop-out animation then start homing
	_launched = true
	var tree := get_tree()
	if tree:
		await tree.create_timer(HOME_DELAY).timeout
		if is_instance_valid(self):
			_launched = false
			_homing = true

func _physics_process(delta: float) -> void:
	if _launched:
		# Fly outward with deceleration
		global_position += _launch_velocity * delta
		_launch_velocity = _launch_velocity.lerp(Vector2.ZERO, 5.0 * delta)
		# Gentle bob
		if is_instance_valid(_sprite):
			_sprite.offset.y = sin(Time.get_ticks_msec() * 0.01) * 2.0
		return

	if _homing:
		var player: PlayerController = GameManager.get_player()
		if not is_instance_valid(player):
			return
		var dir: Vector2 = (player.global_position - global_position)
		if dir.length() < 12.0:
			_collect(player)
			return
		global_position += dir.normalized() * HOME_SPEED * delta

	# Gentle bob while waiting
	if is_instance_valid(_sprite):
		_sprite.offset.y = sin(Time.get_ticks_msec() * 0.008) * 2.0

func _on_collected(_area: Area2D) -> void:
	var player: PlayerController = GameManager.get_player()
	if is_instance_valid(player):
		_collect(player)

func _on_body_collected(body: Node2D) -> void:
	if body is PlayerController:
		_collect(body)

func _collect(player: PlayerController) -> void:
	if _collected:
		return
	_collected = true
	_homing = false
	_launched = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	match pickup_type:
		PickupType.HEALTH:
			if player.has_node("HealthComponent"):
				var health: HealthComponent = player.get_node("HealthComponent")
				health.heal(HEALTH_AMOUNT)
				DamageNumber.spawn_text(player.get_parent(), player.global_position, "+%d HP" % int(HEALTH_AMOUNT), Color(0.3, 1.0, 0.4))
		PickupType.MANA:
			if player.has_node("ManaComponent"):
				var mana: ManaComponent = player.get_node("ManaComponent")
				mana.add_mana(MANA_AMOUNT)
				DamageNumber.spawn_text(player.get_parent(), player.global_position, "+%d MP" % int(MANA_AMOUNT), Color(0.4, 0.5, 1.0))

	# Collection flash
	var parent := get_parent()
	if parent:
		var flash := Sprite2D.new()
		var color: Color = Color(0.3, 1.0, 0.4, 0.6) if pickup_type == PickupType.HEALTH else Color(0.4, 0.5, 1.0, 0.6)
		flash.texture = PlaceholderSprites.create_circle_texture(8, color)
		flash.global_position = global_position
		flash.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		parent.add_child(flash)
		var tween := flash.create_tween().set_parallel(true)
		tween.tween_property(flash, "scale", Vector2(2.0, 2.0), 0.15)
		tween.tween_property(flash, "modulate:a", 0.0, 0.15)
		tween.chain().tween_callback(flash.queue_free)

	queue_free()
