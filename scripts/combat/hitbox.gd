class_name Hitbox
extends Area2D

## Hitbox emits `hit_landed` when touching a Hurtbox and notifies the target.
## This is the counterpart to Hurtbox in a classic hit/hurtbox pattern.

signal hit_landed(hurtbox: Area2D)

@export var damage: float = 10.0

func _ready() -> void:
	# `area_entered` is an Area2D signal emitted when colliders overlap.
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	# Only process damage flow if the other body is an actual hurtbox.
	if area is Hurtbox:
		hit_landed.emit(area)
		area.receive_hit(self)
