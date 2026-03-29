class_name ResurrectBehavior
extends Node

## Bone Colossus: resurrects fallen enemies near it as slime minions.

var resurrect_range: float = 200.0
var resurrect_chance: float = 0.4
var resurrect_delay: float = 3.0
var max_resurrections: int = 2

var _resurrections_used: int = 0
var _slime_data: EnemyData = null
var _pending_resurrections: Array[Dictionary] = []  # [{position, timer}]

func _ready() -> void:
	_slime_data = preload("res://resources/enemy_data/slime_data.tres")

	# Listen for enemy deaths after a frame
	await get_tree().process_frame
	_connect_to_enemy_deaths()

func _process(delta: float) -> void:
	var enemy = get_parent()
	if enemy == null or not is_instance_valid(enemy):
		return
	if enemy.current_state == enemy.State.DEAD:
		_pending_resurrections.clear()
		return

	# Tick pending resurrections
	var completed: Array[int] = []
	for i in range(_pending_resurrections.size()):
		_pending_resurrections[i].timer -= delta
		if _pending_resurrections[i].timer <= 0.0:
			completed.append(i)

	for i in range(completed.size() - 1, -1, -1):
		var entry: Dictionary = _pending_resurrections[completed[i]]
		_do_resurrect(enemy, entry.position)
		_pending_resurrections.remove_at(completed[i])

func _connect_to_enemy_deaths() -> void:
	var enemy = get_parent()
	if enemy == null:
		return

	# We'll check deaths via the group — poll on death events isn't ideal,
	# so instead we'll use a signal from HealthComponent on nearby enemies.
	# Since we can't retroactively connect to all enemies, we check the
	# tree for enemies and connect to their health_changed signals.
	for other in enemy.get_tree().get_nodes_in_group("enemies"):
		if other == enemy or not is_instance_valid(other):
			continue
		_try_connect_death(other)

	# Also watch for new enemies joining
	enemy.get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	if node.is_in_group("enemies") and node != get_parent():
		# Defer connection to allow the enemy to fully initialize
		(func() -> void:
			await get_tree().process_frame
			_try_connect_death(node)
		).call()

func _try_connect_death(other: Node) -> void:
	if not is_instance_valid(other):
		return
	var health_comp = other.get_node_or_null("HealthComponent")
	if health_comp and health_comp is HealthComponent:
		if not health_comp.died.is_connected(_on_nearby_enemy_died.bind(other)):
			health_comp.died.connect(_on_nearby_enemy_died.bind(other))

func _on_nearby_enemy_died(dead_enemy: Node) -> void:
	if _resurrections_used >= max_resurrections:
		return
	if not is_instance_valid(dead_enemy):
		return

	var enemy = get_parent()
	if enemy == null or not is_instance_valid(enemy):
		return
	if enemy.current_state == enemy.State.DEAD:
		return

	var dist: float = enemy.global_position.distance_to(dead_enemy.global_position)
	if dist > resurrect_range:
		return

	if randf() > resurrect_chance:
		return

	_resurrections_used += 1
	_pending_resurrections.append({
		"position": dead_enemy.global_position,
		"timer": resurrect_delay
	})

	# VFX: bones gathering
	DamageNumber.spawn_text(enemy.get_parent(), dead_enemy.global_position + Vector2(0, -20), "RISING...", Color(0.4, 0.9, 0.3))
	SpellEffectVisual.spawn_burst(enemy.get_parent(), dead_enemy.global_position, 8.0, Color(0.4, 0.8, 0.3, 0.3), 0.5)

func _do_resurrect(enemy: CharacterBody2D, pos: Vector2) -> void:
	if _slime_data == null:
		return

	# Spawn slime minion at death position
	var offset: Vector2 = pos - enemy.global_position
	enemy.spawn_minion(_slime_data, offset)

	# VFX
	ScreenFX.shake(enemy, 4.0, 0.1)
	SpellEffectVisual.spawn_burst(enemy.get_parent(), pos, 12.0, Color(0.4, 0.9, 0.3, 0.5), 0.35)
	DamageNumber.spawn_text(enemy.get_parent(), pos + Vector2(0, -25), "RISEN!", Color(0.4, 0.9, 0.3))
