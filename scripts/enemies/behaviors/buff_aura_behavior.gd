class_name BuffAuraBehavior
extends Node

## Mushroom Shaman: periodically buffs all nearby enemies with +30% attack damage.

var buff_interval_min: float = 6.0
var buff_interval_max: float = 8.0
var buff_duration: float = 5.0
var buff_range: float = 250.0
var damage_multiplier: float = 1.3

var _next_buff_time: float = 3.0
var _buffed_enemies: Array[Dictionary] = []  # [{enemy, original_damage, expire_time}]

func _process(delta: float) -> void:
	var enemy = get_parent()
	if enemy == null or not is_instance_valid(enemy):
		return
	if enemy.current_state == enemy.State.DEAD:
		return

	# Expire old buffs
	_tick_buffs(delta, enemy)

	_next_buff_time -= delta
	if _next_buff_time <= 0.0:
		_cast_buff(enemy)
		_next_buff_time = randf_range(buff_interval_min, buff_interval_max)

func _cast_buff(shaman: CharacterBody2D) -> void:
	var buffed_any := false

	for other in shaman.get_tree().get_nodes_in_group("enemies"):
		if other == shaman or not is_instance_valid(other):
			continue
		if not other is CharacterBody2D:
			continue
		if other.current_state == other.State.DEAD:
			continue

		var dist: float = shaman.global_position.distance_to(other.global_position)
		if dist > buff_range:
			continue

		# Check if already buffed by us — refresh instead of stacking
		var already_buffed := false
		for entry in _buffed_enemies:
			if entry.enemy == other:
				entry.expire_time = buff_duration
				already_buffed = true
				break

		if not already_buffed:
			var original_damage: float = other.attack_damage
			_buffed_enemies.append({
				"enemy": other,
				"original_damage": original_damage,
				"expire_time": buff_duration
			})
			other.attack_damage = original_damage * damage_multiplier

		# VFX on buffed enemy
		DamageNumber.spawn_text(other.get_parent(), other.global_position + Vector2(0, -30), "EMPOWERED", Color(0.3, 0.8, 0.2))
		SpellEffectVisual.spawn_burst(other.get_parent(), other.global_position, 10.0, Color(0.3, 0.7, 0.1, 0.4), 0.3)
		buffed_any = true

	if buffed_any:
		# VFX on shaman
		SpellEffectVisual.spawn_burst(shaman.get_parent(), shaman.global_position, 15.0, Color(0.4, 0.8, 0.2, 0.5), 0.4)

func _tick_buffs(delta: float, _shaman: CharacterBody2D) -> void:
	var expired: Array[int] = []

	for i in range(_buffed_enemies.size()):
		_buffed_enemies[i].expire_time -= delta
		if _buffed_enemies[i].expire_time <= 0.0:
			expired.append(i)

	# Remove expired buffs in reverse order
	for i in range(expired.size() - 1, -1, -1):
		var entry: Dictionary = _buffed_enemies[expired[i]]
		if is_instance_valid(entry.enemy) and entry.enemy.current_state != entry.enemy.State.DEAD:
			entry.enemy.attack_damage = entry.original_damage
		_buffed_enemies.remove_at(expired[i])

func _notification(what: int) -> void:
	# Clean up all buffs when the shaman dies or is removed
	if what == NOTIFICATION_PREDELETE:
		for entry in _buffed_enemies:
			if is_instance_valid(entry.enemy) and entry.enemy.current_state != entry.enemy.State.DEAD:
				entry.enemy.attack_damage = entry.original_damage
		_buffed_enemies.clear()
