class_name BuffSystem
extends Node

## Manages active buffs on the player: stat modifiers, empowered attacks, damage reduction, etc.

signal buff_applied(buff: Buff)
signal buff_expired(buff: Buff)

var active_buffs: Array[Buff] = []
var player: CharacterBody2D

# Accumulated stat modifiers from active buffs
var bonus_damage: float = 0.0
var bonus_speed: float = 0.0
var damage_reduction: float = 0.0  # 0.0 to 1.0 (percentage)
var empowered_attacks: int = 0  # Next N attacks deal bonus damage
var empower_bonus: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	player = get_parent() as CharacterBody2D

func _process(delta: float) -> void:
	# Tick down timed buffs
	var expired: Array[Buff] = []
	for buff in active_buffs:
		if buff.duration > 0.0:
			buff.remaining -= delta
			if buff.remaining <= 0.0:
				expired.append(buff)

	for buff in expired:
		remove_buff(buff)

func add_buff(buff: Buff) -> void:
	active_buffs.append(buff)
	_apply_buff_stats(buff)
	buff_applied.emit(buff)

	# Visual indicator
	if player:
		_show_buff_visual(buff)

func remove_buff(buff: Buff) -> void:
	if buff in active_buffs:
		active_buffs.erase(buff)
		_remove_buff_stats(buff)
		buff_expired.emit(buff)

func _apply_buff_stats(buff: Buff) -> void:
	match buff.type:
		Buff.Type.DAMAGE_UP:
			bonus_damage += buff.value
		Buff.Type.SPEED_UP:
			bonus_speed += buff.value
			if player:
				player.move_speed += buff.value
		Buff.Type.DEFENSE_UP:
			damage_reduction = min(damage_reduction + buff.value / 100.0, 0.8)
		Buff.Type.EMPOWER_NEXT:
			empowered_attacks += int(buff.stacks)
			empower_bonus = max(empower_bonus, buff.value)
		Buff.Type.DODGE_BOOST:
			if player:
				player.dodge_speed += buff.value
				player.dodge_cooldown = max(0.2, player.dodge_cooldown - 0.2)

func _remove_buff_stats(buff: Buff) -> void:
	match buff.type:
		Buff.Type.DAMAGE_UP:
			bonus_damage -= buff.value
		Buff.Type.SPEED_UP:
			bonus_speed -= buff.value
			if player:
				player.move_speed -= buff.value
		Buff.Type.DEFENSE_UP:
			damage_reduction = max(0.0, damage_reduction - buff.value / 100.0)
		Buff.Type.EMPOWER_NEXT:
			pass  # Stacks consumed on use, not on expiry
		Buff.Type.DODGE_BOOST:
			if player:
				player.dodge_speed -= buff.value
				player.dodge_cooldown += 0.2

func get_modified_damage(base_damage: float) -> float:
	var total: float = base_damage + bonus_damage
	if empowered_attacks > 0:
		total += empower_bonus
		empowered_attacks -= 1
		if empowered_attacks <= 0:
			empower_bonus = 0.0
	return total

func get_damage_after_reduction(incoming: float) -> float:
	return incoming * (1.0 - damage_reduction)

func has_buff_type(type: Buff.Type) -> bool:
	for buff in active_buffs:
		if buff.type == type:
			return true
	return false

func _show_buff_visual(buff: Buff) -> void:
	var color: Color
	match buff.type:
		Buff.Type.DAMAGE_UP: color = Color(1.0, 0.4, 0.2, 0.5)
		Buff.Type.SPEED_UP: color = Color(0.3, 1.0, 0.5, 0.5)
		Buff.Type.DEFENSE_UP: color = Color(0.4, 0.6, 1.0, 0.5)
		Buff.Type.EMPOWER_NEXT: color = Color(1.0, 0.8, 0.2, 0.5)
		Buff.Type.DODGE_BOOST: color = Color(0.8, 0.3, 1.0, 0.5)
		_: color = Color(1.0, 1.0, 1.0, 0.4)
	SpellEffectVisual.spawn_burst(player.get_parent(), player.global_position, 14.0, color, 0.4)
