class_name Hurtbox
extends Area2D

## Hurtbox receives damage events from hitboxes.
## Using a dedicated component lets any actor opt into "can_be_hit" without inheritance.

signal received_hit(hitbox: Hitbox)

var is_invincible: bool = false

func receive_hit(hitbox: Hitbox) -> void:
	# Respect temporary invincibility (dodge windows, hitstun immunity, etc.)
	if is_invincible:
		return
	received_hit.emit(hitbox)
