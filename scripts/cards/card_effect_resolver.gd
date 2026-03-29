class_name CardEffectResolver
extends Node

## Listens for `CardManager.card_played` and runs card effect logic.
## Supports all effect types: damage, heal, buff, debuff, multi-hit, AOE, shield, mana.

var player: CharacterBody2D
var _x_cost_mana: float = 0.0  ## Mana spent on the current X-cost card

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = get_parent().get_parent() as CharacterBody2D
	var card_manager: CardManager = get_parent()
	card_manager.card_played.connect(_on_card_played)

func _on_card_played(card: CardData, _slot_index: int, mana_spent: float) -> void:
	_x_cost_mana = mana_spent
	_flash_card_play()
	for effect in card.effects:
		resolve_effect(effect, card.is_x_cost)

func _flash_card_play() -> void:
	player.modulate = Color(1.3, 1.3, 1.5, 1.0)
	if player.is_inside_tree():
		var timer: SceneTreeTimer = player.get_tree().create_timer(0.08)
		timer.timeout.connect(func() -> void:
			if is_instance_valid(player):
				player.modulate = Color(1, 1, 1, 1)
		)

func resolve_effect(effect: CardEffect, is_x_cost: bool = false) -> void:
	match effect.type:
		CardEffect.EffectType.DAMAGE:
			_resolve_damage(effect, is_x_cost)
		CardEffect.EffectType.HEAL:
			_resolve_heal(effect, is_x_cost)
		CardEffect.EffectType.PROJECTILE:
			_resolve_projectile(effect)
		CardEffect.EffectType.AOE:
			_resolve_aoe(effect, is_x_cost)
		CardEffect.EffectType.BUFF:
			_resolve_buff(effect)
		CardEffect.EffectType.SHIELD:
			_resolve_shield(effect, is_x_cost)
		CardEffect.EffectType.MANA_GEN:
			_resolve_mana_gen(effect)
		CardEffect.EffectType.DEBUFF:
			_resolve_debuff(effect)
		CardEffect.EffectType.MULTI_HIT:
			_resolve_multi_hit(effect, is_x_cost)

func _get_scaled_value(base_value: float, is_x_cost: bool) -> float:
	## For X-cost cards, value acts as a per-mana multiplier.
	if is_x_cost:
		return base_value * _x_cost_mana
	return base_value

func _resolve_damage(effect: CardEffect, is_x_cost: bool = false) -> void:
	var target: Node2D = _find_target(effect.target_mode)
	if target and target.has_node("HealthComponent"):
		var dmg: float = _get_scaled_value(effect.value, is_x_cost)
		target.get_node("HealthComponent").take_damage(dmg)
		SpellEffectVisual.spawn_slash(player.get_parent(), target.global_position,
			(target.global_position - player.global_position).normalized(), Color(1.0, 0.8, 0.2, 0.9))
		DamageNumber.spawn(player.get_parent(), target.global_position, dmg, Color(1.0, 0.9, 0.3))

func _resolve_heal(effect: CardEffect, is_x_cost: bool = false) -> void:
	var health: HealthComponent = player.get_node("HealthComponent")
	var amount: float = _get_scaled_value(effect.value, is_x_cost)
	health.heal(amount)
	SpellEffectVisual.spawn_heal(player.get_parent(), player.global_position)
	DamageNumber.spawn(player.get_parent(), player.global_position, amount, Color(0.3, 1.0, 0.3))

func _resolve_projectile(effect: CardEffect) -> void:
	if effect.effect_scene == null:
		_resolve_damage(effect)
		return

	var projectile: Node = effect.effect_scene.instantiate()
	projectile.global_position = player.global_position

	var target_pos: Vector2 = player.get_global_mouse_position()
	var direction: Vector2 = (target_pos - player.global_position).normalized()
	if projectile.has_method("setup"):
		projectile.call("setup", direction, effect.value)

	player.get_parent().add_child(projectile)

func _resolve_aoe(effect: CardEffect, is_x_cost: bool = false) -> void:
	var enemies: Array[Node] = GameManager.get_enemies()
	var center: Vector2 = player.global_position
	if effect.target_mode == CardEffect.TargetMode.AREA_AT_CURSOR:
		center = player.get_global_mouse_position()

	var dmg: float = _get_scaled_value(effect.value, is_x_cost)
	SpellEffectVisual.spawn_burst(player.get_parent(), center, effect.radius, Color(1.0, 0.5, 0.2, 0.5))

	for enemy in enemies:
		if enemy.global_position.distance_to(center) <= effect.radius:
			if enemy.has_node("HealthComponent"):
				enemy.get_node("HealthComponent").take_damage(dmg)
				DamageNumber.spawn(player.get_parent(), enemy.global_position, dmg, Color(1.0, 0.6, 0.2))

func _resolve_buff(effect: CardEffect) -> void:
	var buff_sys: BuffSystem = player.get_node_or_null("BuffSystem")
	if buff_sys == null:
		return

	var buff_type: Buff.Type
	match effect.buff_type:
		CardEffect.BuffType.SPEED_UP:
			buff_type = Buff.Type.SPEED_UP
		CardEffect.BuffType.DEFENSE_UP:
			buff_type = Buff.Type.DEFENSE_UP
		CardEffect.BuffType.EMPOWER_NEXT:
			buff_type = Buff.Type.EMPOWER_NEXT
		CardEffect.BuffType.DODGE_BOOST:
			buff_type = Buff.Type.DODGE_BOOST
		_:
			buff_type = Buff.Type.DAMAGE_UP

	var duration: float = effect.duration if effect.duration > 0.0 else 5.0
	var buff: Buff = Buff.create(buff_type, effect.value, duration, max(effect.stacks, 1))
	buff_sys.add_buff(buff)

func _resolve_debuff(effect: CardEffect) -> void:
	## Apply debuff to target enemy's DebuffSystem.
	var target: Node2D = _find_target(effect.target_mode)
	if target == null:
		return

	var debuff_sys: Node = target.get_node_or_null("DebuffSystem")
	if debuff_sys == null or not debuff_sys.has_method("add_debuff"):
		return

	var debuff_t: Debuff.Type
	match effect.debuff_type:
		CardEffect.DebuffType.WEAK:
			debuff_t = Debuff.Type.WEAK
		_:
			debuff_t = Debuff.Type.VULNERABLE

	var duration: float = effect.duration if effect.duration > 0.0 else 5.0
	var debuff: Debuff = Debuff.create(debuff_t, duration)
	debuff_sys.call("add_debuff", debuff)

func _resolve_multi_hit(effect: CardEffect, is_x_cost: bool = false) -> void:
	## Deal damage N times with staggered visuals.
	var count: int = max(effect.hit_count, 1)
	for i in range(count):
		_resolve_damage(effect, is_x_cost)
		if i < count - 1 and player.is_inside_tree():
			await player.get_tree().create_timer(0.1).timeout

func _resolve_shield(effect: CardEffect, is_x_cost: bool = false) -> void:
	var health: HealthComponent = player.get_node("HealthComponent")
	var amount: float = _get_scaled_value(effect.value, is_x_cost)
	health.add_shield(amount)
	SpellEffectVisual.spawn_shield(player.get_parent(), player.global_position)
	DamageNumber.spawn(player.get_parent(), player.global_position, amount, Color(0.4, 0.7, 1.0))

func _resolve_mana_gen(effect: CardEffect) -> void:
	var mana: ManaComponent = player.get_node("ManaComponent")
	mana.add_mana(effect.value)
	SpellEffectVisual.spawn_mana_gain(player.get_parent(), player.global_position)

func _find_target(target_mode: CardEffect.TargetMode) -> Node2D:
	match target_mode:
		CardEffect.TargetMode.NEAREST_ENEMY:
			return _find_nearest_enemy()
		CardEffect.TargetMode.SELF:
			return player
		CardEffect.TargetMode.ALL_ENEMIES:
			return _find_nearest_enemy()
		_:
			return _find_nearest_enemy()

func _find_nearest_enemy() -> Node2D:
	var enemies: Array[Node] = GameManager.get_enemies()
	var nearest: Node2D = null
	var nearest_dist: float = INF
	for enemy in enemies:
		var dist: float = player.global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	return nearest
