class_name CardEffectResolver
extends Node

var player: CharacterBody2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = get_parent().get_parent() as CharacterBody2D
	var card_manager: CardManager = get_parent()
	card_manager.card_played.connect(_on_card_played)

func _on_card_played(card: Resource, _slot_index: int) -> void:
	# Flash the card play with a brief visual
	_flash_card_play()
	for effect in card.effects:
		resolve_effect(effect)

func _flash_card_play() -> void:
	# Brief white flash on player to indicate card activation
	player.modulate = Color(1.3, 1.3, 1.5, 1.0)
	var timer: SceneTreeTimer = get_tree().create_timer(0.08)
	timer.timeout.connect(func() -> void: player.modulate = Color(1, 1, 1, 1))

func resolve_effect(effect: Resource) -> void:
	match effect.type:
		CardEffect.EffectType.DAMAGE:
			_resolve_damage(effect)
		CardEffect.EffectType.HEAL:
			_resolve_heal(effect)
		CardEffect.EffectType.PROJECTILE:
			_resolve_projectile(effect)
		CardEffect.EffectType.AOE:
			_resolve_aoe(effect)
		CardEffect.EffectType.BUFF:
			_resolve_buff(effect)
		CardEffect.EffectType.SHIELD:
			_resolve_shield(effect)
		CardEffect.EffectType.MANA_GEN:
			_resolve_mana_gen(effect)

func _resolve_damage(effect: Resource) -> void:
	var target: Node2D = _find_target(effect.target_mode)
	if target and target.has_node("HealthComponent"):
		target.get_node("HealthComponent").take_damage(effect.value)
		# Visual: slash at target + damage number
		SpellEffectVisual.spawn_slash(player.get_parent(), target.global_position,
			(target.global_position - player.global_position).normalized(), Color(1.0, 0.8, 0.2, 0.9))
		DamageNumber.spawn(player.get_parent(), target.global_position, effect.value, Color(1.0, 0.9, 0.3))

func _resolve_heal(effect: Resource) -> void:
	var health: HealthComponent = player.get_node("HealthComponent")
	health.heal(effect.value)
	# Visual: green plus + heal number
	SpellEffectVisual.spawn_heal(player.get_parent(), player.global_position)
	DamageNumber.spawn(player.get_parent(), player.global_position, effect.value, Color(0.3, 1.0, 0.3))

func _resolve_projectile(effect: Resource) -> void:
	if effect.effect_scene == null:
		_resolve_damage(effect)
		return

	var projectile: Node = effect.effect_scene.instantiate()
	projectile.global_position = player.global_position

	var target_pos: Vector2 = player.get_global_mouse_position()
	var direction: Vector2 = (target_pos - player.global_position).normalized()
	if projectile.has_method("setup"):
		projectile.setup(direction, effect.value)

	player.get_parent().add_child(projectile)

func _resolve_aoe(effect: Resource) -> void:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	var center: Vector2 = player.global_position
	if effect.target_mode == CardEffect.TargetMode.AREA_AT_CURSOR:
		center = player.get_global_mouse_position()

	# Visual: AOE burst
	SpellEffectVisual.spawn_burst(player.get_parent(), center, effect.radius, Color(1.0, 0.5, 0.2, 0.5))

	for enemy in enemies:
		if enemy.global_position.distance_to(center) <= effect.radius:
			if enemy.has_node("HealthComponent"):
				enemy.get_node("HealthComponent").take_damage(effect.value)
				DamageNumber.spawn(player.get_parent(), enemy.global_position, effect.value, Color(1.0, 0.6, 0.2))

func _resolve_buff(effect: Resource) -> void:
	var original_speed: float = player.move_speed
	player.move_speed *= (1.0 + effect.value / 100.0)

	# Visual: buff aura
	SpellEffectVisual.spawn_burst(player.get_parent(), player.global_position, 12.0, Color(1.0, 1.0, 0.3, 0.4), effect.duration * 0.1)

	var timer: SceneTreeTimer = get_tree().create_timer(effect.duration)
	timer.timeout.connect(func() -> void: player.move_speed = original_speed)

func _resolve_shield(effect: Resource) -> void:
	var health: HealthComponent = player.get_node("HealthComponent")
	health.current_health = min(health.current_health + effect.value, health.max_health + effect.value)
	health.health_changed.emit(health.current_health, health.max_health)
	# Visual: shield bubble
	SpellEffectVisual.spawn_shield(player.get_parent(), player.global_position)
	DamageNumber.spawn(player.get_parent(), player.global_position, effect.value, Color(0.4, 0.7, 1.0))

func _resolve_mana_gen(effect: Resource) -> void:
	var mana: ManaComponent = player.get_node("ManaComponent")
	mana.add_mana(effect.value)
	# Visual: blue sparkles rising
	SpellEffectVisual.spawn_mana_gain(player.get_parent(), player.global_position)

func _find_target(target_mode: CardEffect.TargetMode) -> Node2D:
	match target_mode:
		CardEffect.TargetMode.NEAREST_ENEMY:
			return _find_nearest_enemy()
		CardEffect.TargetMode.SELF:
			return player
		_:
			return _find_nearest_enemy()

func _find_nearest_enemy() -> Node2D:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist: float = INF
	for enemy in enemies:
		var dist: float = player.global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	return nearest
