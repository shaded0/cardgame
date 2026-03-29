class_name Hitbox
extends Area2D

signal hit_landed(hurtbox: Area2D)

@export var damage: float = 10.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		hit_landed.emit(area)
		area.receive_hit(self)
