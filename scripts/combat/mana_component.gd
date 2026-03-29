class_name ManaComponent
extends Node

signal mana_changed(current: float, maximum: float)

@export var max_mana: float = 100.0
@export var mana_per_hit_dealt: float = 10.0
@export var mana_per_hit_taken: float = 15.0

var current_mana: float = 0.0

func add_mana(amount: float) -> void:
	current_mana = min(current_mana + amount, max_mana)
	mana_changed.emit(current_mana, max_mana)

func spend_mana(amount: float) -> bool:
	if current_mana < amount:
		return false
	current_mana -= amount
	mana_changed.emit(current_mana, max_mana)
	return true

func on_basic_attack_hit() -> void:
	add_mana(mana_per_hit_dealt)

func on_damage_taken() -> void:
	add_mana(mana_per_hit_taken)
