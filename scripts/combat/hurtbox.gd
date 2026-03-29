class_name Hurtbox
extends Area2D

signal received_hit(hitbox: Hitbox)

var is_invincible: bool = false

func receive_hit(hitbox: Hitbox) -> void:
	if is_invincible:
		return
	received_hit.emit(hitbox)
