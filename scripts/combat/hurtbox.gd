class_name Hurtbox
extends Area2D

## Hurtbox receives damage events from hitboxes.
## Supports temporary invincibility (dodge, post-hit i-frames).

signal received_hit(hitbox: Hitbox)

var is_invincible: bool = false

## Duration of post-hit invincibility frames (0 = disabled).
@export var iframes_duration: float = 0.2

## Visual flash during i-frames so player can see the window.
var _iframes_flash_active: bool = false

func receive_hit(hitbox: Hitbox) -> void:
	if is_invincible:
		return
	received_hit.emit(hitbox)
	# Grant brief invincibility after taking a hit to prevent burst damage.
	if iframes_duration > 0.0:
		_start_iframes()

func _start_iframes() -> void:
	is_invincible = true
	_iframes_flash_active = true

	# Flicker the parent to visually communicate i-frames.
	var owner_node: Node2D = get_parent() as Node2D
	if owner_node and is_inside_tree():
		var tree: SceneTree = get_tree()
		if tree == null:
			is_invincible = false
			_iframes_flash_active = false
			return

		# Use one tween instead of a timer loop to reduce per-hit coroutine churn.
		var tween := owner_node.create_tween()
		tween.set_loops(maxi(int(ceil(iframes_duration / 0.06)), 1))
		tween.tween_property(owner_node, "modulate:a", 0.3, 0.03)
		tween.tween_property(owner_node, "modulate:a", 1.0, 0.03)
		await tree.create_timer(iframes_duration, true, false, true).timeout
		if is_instance_valid(owner_node):
			owner_node.modulate.a = 1.0
			if tween.is_valid():
				tween.kill()

	is_invincible = false
	_iframes_flash_active = false
