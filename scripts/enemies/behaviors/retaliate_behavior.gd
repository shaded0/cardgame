class_name RetaliateBehavior
extends Node

## Iron Beetle: spike burst retaliation when hit.

var retaliate_chance: float = 0.6
var retaliate_damage: float = 8.0
var retaliate_range: float = 80.0
var retaliate_cooldown: float = 2.0

var _cooldown_timer: float = 0.0
var _connected: bool = false

func _ready() -> void:
	# Connect after a frame so the enemy is fully initialized
	await get_tree().process_frame
	var enemy = get_parent()
	if enemy and is_instance_valid(enemy) and enemy.has_node("Hurtbox"):
		var hurtbox: Hurtbox = enemy.get_node("Hurtbox")
		hurtbox.received_hit.connect(_on_enemy_hit)
		_connected = true

func _process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta

func _on_enemy_hit(_incoming_hitbox: Hitbox) -> void:
	if _cooldown_timer > 0.0:
		return
	if randf() > retaliate_chance:
		return

	var enemy = get_parent()
	if enemy == null or not is_instance_valid(enemy):
		return
	if enemy.current_state == enemy.State.DEAD:
		return
	if enemy.player == null or not is_instance_valid(enemy.player):
		return

	var dist: float = enemy.global_position.distance_to(enemy.player.global_position)
	if dist > retaliate_range:
		return

	_cooldown_timer = retaliate_cooldown
	_do_spike_burst(enemy)

func _do_spike_burst(enemy: CharacterBody2D) -> void:
	# Visual: spike ring burst
	SpellEffectVisual.spawn_burst(enemy.get_parent(), enemy.global_position, retaliate_range * 0.4, Color(0.8, 0.5, 0.2, 0.6), 0.3)
	ScreenFX.spawn_impact_ring(enemy.get_parent(), enemy.global_position, Color(0.9, 0.5, 0.2, 0.5), retaliate_range * 0.5)
	DamageNumber.spawn_text(enemy.get_parent(), enemy.global_position + Vector2(0, -30), "SPIKES!", Color(0.9, 0.5, 0.2))

	# Create a brief Area2D to detect player
	var burst := Area2D.new()
	burst.global_position = enemy.global_position
	burst.collision_layer = 0
	burst.collision_mask = 0

	var hitbox := Hitbox.new()
	hitbox.damage = retaliate_damage
	hitbox.one_shot = true
	hitbox.collision_layer = 64  # Enemy projectile layer
	hitbox.collision_mask = 16   # Player hurtbox layer
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = retaliate_range
	shape.shape = circle
	hitbox.add_child(shape)
	burst.add_child(hitbox)

	var parent: Node = enemy.get_parent()
	if parent:
		parent.add_child(burst)
		# Remove after a brief moment
		var tween := burst.create_tween()
		tween.tween_interval(0.1)
		tween.tween_callback(burst.queue_free)
