class_name BossPhaseBehavior
extends Node

## Stone Golem boss phases: enrages at 50% HP, spawns minions periodically.

var phase: int = 1
var minion_spawn_interval: float = 15.0
var _minion_timer: float = 0.0
var _enraged: bool = false
var _slime_data: EnemyData = null

func _ready() -> void:
	_slime_data = preload("res://resources/enemy_data/slime_data.tres")

	# Connect to health changes after a frame so the enemy is fully initialized
	await get_tree().process_frame
	var enemy = get_parent()
	if enemy and enemy.has_node("HealthComponent"):
		enemy.get_node("HealthComponent").health_changed.connect(_on_health_changed)

func _process(delta: float) -> void:
	var enemy = get_parent()
	if enemy == null or not is_instance_valid(enemy):
		return
	if enemy.current_state == enemy.State.DEAD:
		return

	# Phase 2: periodic minion spawning
	if _enraged:
		_minion_timer -= delta
		if _minion_timer <= 0.0:
			_spawn_minions(enemy)
			_minion_timer = minion_spawn_interval

func _on_health_changed(current: float, maximum: float) -> void:
	if _enraged:
		return

	# Enrage at 50% HP
	if current <= maximum * 0.5:
		_enrage()

func _enrage() -> void:
	_enraged = true
	phase = 2
	_minion_timer = 5.0  # First minions come after 5s

	var enemy = get_parent()
	if enemy == null or not is_instance_valid(enemy):
		return

	# Stat boost
	enemy.move_speed *= 2.0
	enemy.attack_damage *= 1.5

	# Enrage flash VFX
	ScreenFX.shake(enemy, 15.0, 0.3)
	SpellEffectVisual.spawn_burst(enemy.get_parent(), enemy.global_position, 30.0, Color(1.0, 0.3, 0.1, 0.6), 0.5)
	DamageNumber.spawn_text(enemy.get_parent(), enemy.global_position + Vector2(0, -40), "ENRAGED!", Color(1.0, 0.3, 0.1))

	# Red tint
	var tween := enemy.create_tween()
	tween.tween_property(enemy, "modulate", Color(1.3, 0.7, 0.6, 1.0), 0.3)
	tween.tween_property(enemy, "modulate", Color(1.15, 0.85, 0.8, 1.0), 0.3)

func _spawn_minions(enemy: CharacterBody2D) -> void:
	if _slime_data == null:
		return

	ScreenFX.shake(enemy, 8.0, 0.15)
	DamageNumber.spawn_text(enemy.get_parent(), enemy.global_position + Vector2(0, -30), "SUMMON!", Color(0.8, 0.5, 0.2))

	for i in range(2):
		var angle: float = randf() * TAU
		var offset := Vector2(cos(angle), sin(angle) * 0.5) * randf_range(60.0, 100.0)
		enemy.spawn_minion(_slime_data, offset)

		# Spawn VFX at minion location
		SpellEffectVisual.spawn_burst(enemy.get_parent(), enemy.global_position + offset, 10.0, Color(0.5, 0.8, 0.3, 0.4), 0.3)
