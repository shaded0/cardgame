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

		# Rapid alpha flicker during i-frame window.
		var elapsed: float = 0.0
		var flicker_interval: float = 0.06
		while elapsed < iframes_duration:
			if not is_instance_valid(owner_node) or not is_inside_tree():
				break
			owner_node.modulate.a = 0.3 if int(elapsed / flicker_interval) % 2 == 0 else 1.0
			await tree.create_timer(flicker_interval, true, false, true).timeout
			elapsed += flicker_interval

		# Restore
		if is_instance_valid(owner_node):
			owner_node.modulate.a = 1.0

	is_invincible = false
	_iframes_flash_active = false
