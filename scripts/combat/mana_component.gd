class_name ManaComponent
extends Node

## Tracks mana as an independent component.
## This keeps player health/attack logic simpler and reusable.

signal mana_changed(current: float, maximum: float)

@export var max_mana: float = 100.0
@export var mana_per_hit_dealt: float = 10.0
@export var mana_per_hit_taken: float = 15.0
@export var starting_mana_percent: float = 0.4  ## Start fights with 40% mana so cards matter immediately
@export var passive_regen_rate: float = 3.0     ## Mana per second — keeps cards relevant mid-fight

var current_mana: float = 0.0

func _ready() -> void:
	# Keep mana calculations responsive even during pause menus.
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	# Passive mana regen so players aren't starved between melee exchanges.
	if passive_regen_rate > 0.0 and current_mana < max_mana:
		add_mana(passive_regen_rate * delta, false)

func initialize() -> void:
	## Call at fight start to front-load mana.
	current_mana = clampf(max_mana * starting_mana_percent, 0.0, max_mana)
	mana_changed.emit(current_mana, max_mana)

func add_mana(amount: float, show_fx: bool = true) -> void:
	if amount <= 0.0:
		return

	# Clamp mana to max and emit once so UI updates reliably.
	var old_mana: float = current_mana
	var new_mana: float = min(current_mana + amount, max_mana)
	if is_equal_approx(new_mana, old_mana):
		return
	current_mana = new_mana
	mana_changed.emit(current_mana, max_mana)

	# Show mana gain visual if we actually gained mana
	if show_fx and current_mana > old_mana:
		var owner_node: Node2D = get_parent() as Node2D
		if owner_node and owner_node.is_in_group("player"):
			SpellEffectVisual.spawn_mana_gain(owner_node.get_parent(), owner_node.global_position)

func spend_mana(amount: float) -> bool:
	# Return false for callers to cancel action if not enough mana.
	if amount <= 0.0:
		return false
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
