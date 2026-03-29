class_name ScreamBehavior
extends Node

## Banshee: interruptible scream that increases card mana costs.

var scream_interval_min: float = 8.0
var scream_interval_max: float = 10.0
var channel_duration: float = 1.0
var mana_cost_increase: float = 10.0
var cost_debuff_duration: float = 4.0

var _next_scream_time: float = 5.0
var _is_channeling: bool = false
var _channel_timer: float = 0.0
var _warning_sprite: Sprite2D = null

func _process(delta: float) -> void:
	var enemy = get_parent()
	if enemy == null or not is_instance_valid(enemy):
		return
	if enemy.current_state == enemy.State.DEAD:
		_cancel_channel()
		return

	if _is_channeling:
		# Check if interrupted (took damage → entered HURT state)
		if enemy.current_state == enemy.State.HURT:
			_cancel_channel()
			_next_scream_time = randf_range(scream_interval_min, scream_interval_max)
			return

		_channel_timer -= delta
		if _channel_timer <= 0.0:
			_complete_scream(enemy)
		return

	_next_scream_time -= delta
	if _next_scream_time <= 0.0 and enemy.current_state == enemy.State.CHASE:
		_start_channel(enemy)

func before_physics(enemy: CharacterBody2D, _delta: float) -> bool:
	if not _is_channeling:
		return false

	# Stop movement during channel
	enemy.velocity = Vector2.ZERO
	enemy._play_anim(&"idle")
	return true

func _start_channel(enemy: CharacterBody2D) -> void:
	_is_channeling = true
	_channel_timer = channel_duration

	# Purple warning ring expanding
	_warning_sprite = Sprite2D.new()
	_warning_sprite.texture = PlaceholderSprites.create_circle_texture(60, Color(0.5, 0.1, 0.6, 0.3))
	_warning_sprite.global_position = enemy.global_position
	_warning_sprite.z_index = -1
	_warning_sprite.scale = Vector2(0.2, 0.2)
	var parent: Node = enemy.get_parent()
	if parent:
		parent.add_child(_warning_sprite)
		var tween := _warning_sprite.create_tween()
		tween.tween_property(_warning_sprite, "scale", Vector2(1.2, 1.2), channel_duration).set_ease(Tween.EASE_OUT)

	# Flash purple during channel
	if is_instance_valid(enemy.anim_sprite):
		enemy.anim_sprite.modulate = Color(1.2, 0.6, 1.5, 1.0)

func _complete_scream(enemy: CharacterBody2D) -> void:
	_is_channeling = false
	_next_scream_time = randf_range(scream_interval_min, scream_interval_max)
	_cleanup_warning()

	# Apply mana cost increase to player's CardManager
	var player = enemy.player
	if player and is_instance_valid(player):
		var card_manager = player.get_node_or_null("CardManager")
		if card_manager and card_manager.has_method("apply_mana_cost_modifier"):
			card_manager.apply_mana_cost_modifier(mana_cost_increase, cost_debuff_duration)

	# Scream VFX
	ScreenFX.shake(enemy, 8.0, 0.2)
	SpellEffectVisual.spawn_burst(enemy.get_parent(), enemy.global_position, 25.0, Color(0.5, 0.2, 0.7, 0.5), 0.4)
	DamageNumber.spawn_text(enemy.get_parent(), enemy.global_position + Vector2(0, -40), "SILENCE!", Color(0.6, 0.2, 0.8))

	# Restore modulate
	if is_instance_valid(enemy):
		enemy._restore_modulate()

func _cancel_channel() -> void:
	_is_channeling = false
	_channel_timer = 0.0
	_cleanup_warning()

	var enemy = get_parent()
	if enemy and is_instance_valid(enemy):
		DamageNumber.spawn_text(enemy.get_parent(), enemy.global_position + Vector2(0, -30), "INTERRUPTED!", Color(0.8, 0.8, 0.2))
		enemy._restore_modulate()

func _cleanup_warning() -> void:
	if _warning_sprite and is_instance_valid(_warning_sprite):
		_warning_sprite.queue_free()
		_warning_sprite = null
