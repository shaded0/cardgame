class_name BlockBehavior
extends Node

## Skeleton block behavior: periodically raises a shield that reduces incoming damage by 50%.

## How long each shield phase lasts.
var _block_timer: float = 0.0
## Min duration for active block; tune lower for faster rhythm.
var _block_duration: float = 2.0
## Minimum cooldown between block windows.
var _block_cooldown_min: float = 5.0
## Maximum cooldown to add variance and anti-pattern feel.
var _block_cooldown_max: float = 8.0
## Countdown until next block phase starts.
var _next_block_time: float = 0.0
## Whether block window is currently active.
var _is_blocking: bool = false
## Optional modulate tween handle used for cleanup/cancel.
var _block_tween: Tween = null

## Initialize the first block cooldown window when spawned.
func _ready() -> void:
	_next_block_time = randf_range(_block_cooldown_min, _block_cooldown_max)

## Tick block rhythm and end/start windows when timers expire.
func _process(delta: float) -> void:
	var enemy = get_parent()
	if enemy == null or not is_instance_valid(enemy):
		return
	if enemy.current_state == enemy.State.DEAD:
		return

	if _is_blocking:
		_block_timer -= delta
		if _block_timer <= 0.0:
			_end_block()
	else:
		_next_block_time -= delta
		if _next_block_time <= 0.0:
			_start_block()

## Damage reduction value currently granted by this behavior.
func get_damage_reduction() -> float:
	return 0.5 if _is_blocking else 0.0

## Enter blocking state and provide a strong visual/readability cue.
func _start_block() -> void:
	_is_blocking = true
	_block_timer = _block_duration

	var enemy = get_parent()
	if enemy and is_instance_valid(enemy):
		# Blue tint to indicate blocking
		if _block_tween and _block_tween.is_valid():
			_block_tween.kill()
		_block_tween = enemy.create_tween()
		_block_tween.tween_property(enemy, "modulate", Color(0.6, 0.7, 1.2, 1.0), 0.15)

		DamageNumber.spawn_text(enemy.get_parent(), enemy.global_position + Vector2(0, -35), "BLOCK", Color(0.5, 0.7, 1.0))

## Exit blocking state and schedule next uptime window.
func _end_block() -> void:
	_is_blocking = false
	_next_block_time = randf_range(_block_cooldown_min, _block_cooldown_max)

	var enemy = get_parent()
	if enemy and is_instance_valid(enemy):
		if _block_tween and _block_tween.is_valid():
			_block_tween.kill()
		_block_tween = enemy.create_tween()
		_block_tween.tween_property(enemy, "modulate", Color(1, 1, 1, 1), 0.2)
