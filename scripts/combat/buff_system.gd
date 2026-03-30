class_name BuffSystem
extends Node

## Manages active buffs on the player: stat modifiers, empowered attacks, damage reduction, etc.
## Buff objects are plain data (`Buff`) with lifecycle managed here each frame.

signal buff_applied(buff: Buff)
signal buff_expired(buff: Buff)

var active_buffs: Array[Buff] = []
var player: CharacterBody2D

# Accumulated stat modifiers from active buffs
var bonus_damage: float = 0.0
var bonus_speed: float = 0.0
var damage_reduction: float = 0.0  # 0.0 to 1.0 (percentage)
var _damage_reduction_total: float = 0.0
var empowered_attacks: int = 0  # Next N attacks deal bonus damage
var empower_bonus: float = 0.0

func _ready() -> void:
	# Inherit means this node follows parent pause/process behavior by default.
	process_mode = Node.PROCESS_MODE_INHERIT
	player = get_parent() as CharacterBody2D

func _process(delta: float) -> void:
	# Tick down timed buffs each frame and collect those with expired durations.
	var expired: Array[Buff] = []
	for buff in active_buffs:
		if buff.duration > 0.0:
			buff.remaining -= delta
			if buff.remaining <= 0.0:
				expired.append(buff)

	for buff in expired:
		remove_buff(buff)

func add_buff(buff: Buff) -> void:
	# Add and apply immediately so effects take effect same frame.
	active_buffs.append(buff)
	_apply_buff_stats(buff)
	buff_applied.emit(buff)

	# Visual indicator
	if player:
		_show_buff_visual(buff)

func remove_buff(buff: Buff) -> void:
	# Remove from both list and applied stats for clean stat rollback.
	if buff in active_buffs:
		active_buffs.erase(buff)
		_remove_buff_stats(buff)
		buff_expired.emit(buff)

func _apply_buff_stats(buff: Buff) -> void:
	# Centralized stat mutation by type keeps stacking behavior explicit.
	match buff.type:
		Buff.Type.DAMAGE_UP:
			bonus_damage += buff.value
		Buff.Type.SPEED_UP:
			bonus_speed += buff.value
			if player:
				player.move_speed += buff.value
		Buff.Type.DEFENSE_UP:
			_damage_reduction_total += buff.value / 100.0
			damage_reduction = min(_damage_reduction_total, 0.8)
		Buff.Type.EMPOWER_NEXT:
			_recompute_empower_state()
		Buff.Type.DODGE_BOOST:
			if player:
				player.dodge_speed += buff.value
				player.dodge_cooldown = max(0.2, player.dodge_cooldown - 0.2)

func _remove_buff_stats(buff: Buff) -> void:
	# Reverse operations from _apply_buff_stats so values stay numerically stable.
	match buff.type:
		Buff.Type.DAMAGE_UP:
			bonus_damage -= buff.value
		Buff.Type.SPEED_UP:
			bonus_speed -= buff.value
			if player:
				player.move_speed -= buff.value
		Buff.Type.DEFENSE_UP:
			_damage_reduction_total = max(0.0, _damage_reduction_total - buff.value / 100.0)
			damage_reduction = min(_damage_reduction_total, 0.8)
		Buff.Type.EMPOWER_NEXT:
			_recompute_empower_state()
		Buff.Type.DODGE_BOOST:
			if player:
				player.dodge_speed -= buff.value
				player.dodge_cooldown += 0.2

func get_modified_damage(base_damage: float) -> float:
	# Consume one empowered stack if available and apply temporary bonus damage.
	var total: float = base_damage + bonus_damage
	if empowered_attacks > 0:
		total += empower_bonus
		_consume_empower_stack()
	return total

func get_damage_after_reduction(incoming: float) -> float:
	# Simple multiplicative reduction. E.g. 0.25 => reduce by 25%.
	return incoming * (1.0 - damage_reduction)

func has_buff_type(type: Buff.Type) -> bool:
	# Useful for UI/logic checks without exposing internal array.
	for buff in active_buffs:
		if buff.type == type:
			return true
	return false

func _recompute_empower_state() -> void:
	empowered_attacks = 0
	empower_bonus = 0.0
	for buff in active_buffs:
		if buff.type != Buff.Type.EMPOWER_NEXT or buff.stacks <= 0:
			continue
		empowered_attacks += buff.stacks
		empower_bonus = max(empower_bonus, buff.value)

func _consume_empower_stack() -> void:
	var strongest_buff: Buff = null
	for buff in active_buffs:
		if buff.type != Buff.Type.EMPOWER_NEXT or buff.stacks <= 0:
			continue
		if strongest_buff == null or buff.value > strongest_buff.value:
			strongest_buff = buff

	if strongest_buff == null:
		_recompute_empower_state()
		return

	strongest_buff.stacks -= 1
	if strongest_buff.stacks <= 0:
		active_buffs.erase(strongest_buff)
		buff_expired.emit(strongest_buff)

	_recompute_empower_state()

func _show_buff_visual(buff: Buff) -> void:
	# Small temporary burst gives immediate user feedback when a buff is granted.
	var color: Color
	match buff.type:
		Buff.Type.DAMAGE_UP: color = Color(1.0, 0.4, 0.2, 0.5)
		Buff.Type.SPEED_UP: color = Color(0.3, 1.0, 0.5, 0.5)
		Buff.Type.DEFENSE_UP: color = Color(0.4, 0.6, 1.0, 0.5)
		Buff.Type.EMPOWER_NEXT: color = Color(1.0, 0.8, 0.2, 0.5)
		Buff.Type.DODGE_BOOST: color = Color(0.8, 0.3, 1.0, 0.5)
		_: color = Color(1.0, 1.0, 1.0, 0.4)
	SpellEffectVisual.spawn_burst(player.get_parent(), player.global_position, 14.0, color, 0.4)
