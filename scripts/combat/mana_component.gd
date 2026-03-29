class_name ManaComponent
extends Node

## Tracks mana as an independent component.
## This keeps player health/attack logic simpler and reusable.

signal mana_changed(current: float, maximum: float)

@export var max_mana: float = 100.0
@export var mana_per_hit_dealt: float = 10.0
@export var mana_per_hit_taken: float = 15.0

var current_mana: float = 0.0

func _ready() -> void:
	# Keep mana calculations responsive even during pause menus.
	process_mode = Node.PROCESS_MODE_ALWAYS

func add_mana(amount: float) -> void:
	# Clamp mana to max and emit once so UI updates reliably.
	var old_mana: float = current_mana
	current_mana = min(current_mana + amount, max_mana)
	mana_changed.emit(current_mana, max_mana)

	# Show mana gain visual if we actually gained mana
	if current_mana > old_mana and amount > 0:
		var owner_node: Node2D = get_parent() as Node2D
		if owner_node and owner_node.is_in_group("player"):
			SpellEffectVisual.spawn_mana_gain(owner_node.get_parent(), owner_node.global_position)

func spend_mana(amount: float) -> bool:
	# Return false for callers to cancel action if not enough mana.
	if current_mana < amount:
		return false
	current_mana -= amount
	mana_changed.emit(current_mana, max_mana)
	return true

func on_basic_attack_hit() -> void:
	# Hooked by hitbox signal for automatic mana rewards.
	add_mana(mana_per_hit_dealt)

func on_damage_taken() -> void:
	# Hooked by hurtbox signal for defensive resource gain.
	add_mana(mana_per_hit_taken)
