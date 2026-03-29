extends RefCounted

const FakePlayerScript = preload("res://tests/support/fake_player.gd")
const PlayerControllerScript = preload("res://scripts/player/player.gd")
const PlayerStateMachineScript = preload("res://scripts/player/player_state_machine.gd")
const IdleStateScript = preload("res://scripts/player/player_states/idle_state.gd")
const MoveStateScript = preload("res://scripts/player/player_states/move_state.gd")
const AttackStateScript = preload("res://scripts/player/player_states/attack_state.gd")
const DodgeStateScript = preload("res://scripts/player/player_states/dodge_state.gd")
const HitboxScript = preload("res://scripts/combat/hitbox.gd")
const HurtboxScript = preload("res://scripts/combat/hurtbox.gd")
const HealthComponentScript = preload("res://scripts/combat/health_component.gd")
const ManaComponentScript = preload("res://scripts/combat/mana_component.gd")
const BuffSystemScript = preload("res://scripts/combat/buff_system.gd")
const CardManagerScript = preload("res://scripts/cards/card_manager.gd")
const CardEffectResolverScript = preload("res://scripts/cards/card_effect_resolver.gd")
const GameManagerScript = preload("res://scripts/managers/game_manager.gd")
const CardDataScript = preload("res://resources/cards/card_data.gd")
const CardEffectScript = preload("res://resources/cards/card_effect.gd")
const ClassConfigScript = preload("res://resources/classes/class_config.gd")
const RoomDataScript = preload("res://resources/rooms/room_data.gd")

static func make_player(root: Node, add_player_group: bool = true) -> CharacterBody2D:
	var player: CharacterBody2D = FakePlayerScript.new()
	player.name = "Player"
	root.add_child(player)
	if add_player_group:
		player.add_to_group("player")
	return player

static func make_player_controller(root: Node, config: ClassConfig = null) -> PlayerController:
	GameManager.current_class_config = config

	var player := PlayerControllerScript.new()
	player.name = "Player"

	var hitbox := HitboxScript.new()
	hitbox.name = "Hitbox"
	hitbox.add_child(_make_collision_shape("CollisionShape2D"))
	player.add_child(hitbox)

	var hurtbox := HurtboxScript.new()
	hurtbox.name = "Hurtbox"
	player.add_child(hurtbox)

	var animated_sprite := AnimatedSprite2D.new()
	animated_sprite.name = "AnimatedSprite"
	player.add_child(animated_sprite)

	var body_shape := CollisionShape2D.new()
	body_shape.name = "CollisionShape2D"
	var body_circle := CircleShape2D.new()
	body_circle.radius = 14.0
	body_shape.shape = body_circle
	player.add_child(body_shape)

	player.add_child(_make_named_child(HealthComponentScript, "HealthComponent"))
	player.add_child(_make_named_child(ManaComponentScript, "ManaComponent"))
	player.add_child(_make_named_child(CardManagerScript, "CardManager"))
	player.add_child(_make_named_child(BuffSystemScript, "BuffSystem"))

	var state_machine := PlayerStateMachineScript.new()
	state_machine.name = "StateMachine"
	state_machine.add_child(_make_named_child(IdleStateScript, "Idle"))
	state_machine.add_child(_make_named_child(MoveStateScript, "Move"))
	state_machine.add_child(_make_named_child(AttackStateScript, "Attack"))
	state_machine.add_child(_make_named_child(DodgeStateScript, "Dodge"))
	player.add_child(state_machine)

	root.add_child(player)
	player.add_to_group("player")
	return player

static func make_enemy(root: Node, position: Vector2, max_health: float = 50.0) -> Node2D:
	var enemy := Node2D.new()
	enemy.name = "Enemy"
	root.add_child(enemy)
	enemy.add_to_group("enemies")
	enemy.global_position = position
	add_health(enemy, max_health)
	return enemy

static func add_health(owner: Node, max_health: float = 100.0, current_health: float = -1.0) -> Node:
	var health = HealthComponentScript.new()
	health.name = "HealthComponent"
	health.max_health = max_health
	owner.add_child(health)
	if current_health >= 0.0:
		health.set_current_health(current_health)
	return health

static func add_mana(owner: Node, max_mana: float = 100.0, current_mana: float = 0.0) -> Node:
	var mana = ManaComponentScript.new()
	mana.name = "ManaComponent"
	mana.max_mana = max_mana
	owner.add_child(mana)
	mana.current_mana = current_mana
	return mana

static func add_buff_system(owner: Node) -> Node:
	var buff_system = BuffSystemScript.new()
	buff_system.name = "BuffSystem"
	owner.add_child(buff_system)
	return buff_system

static func add_card_manager(owner: Node) -> Node:
	var card_manager = CardManagerScript.new()
	card_manager.name = "CardManager"
	owner.add_child(card_manager)
	return card_manager

static func add_card_resolver(card_manager: Node) -> Node:
	var resolver = CardEffectResolverScript.new()
	resolver.name = "CardEffectResolver"
	card_manager.add_child(resolver)
	return resolver

static func make_game_manager(root: Node) -> Node:
	var manager = GameManagerScript.new()
	manager.name = "GameManagerUnderTest"
	root.add_child(manager)
	return manager

static func make_card(
	card_name: String,
	mana_cost: int = 0,
	chain_card: Resource = null,
	generates_mana: int = 0,
	pauses_game: bool = false,
	effects: Array[Resource] = []
) -> Resource:
	var card = CardDataScript.new()
	card.card_name = card_name
	card.mana_cost = mana_cost
	card.chain_card = chain_card
	card.generates_mana = generates_mana
	card.pauses_game = pauses_game
	card.effects = effects
	return card

static func make_effect(
	effect_type: int,
	value: float = 0.0,
	target_mode: int = 0,
	radius: float = 0.0,
	duration: float = 0.0
) -> Resource:
	var effect = CardEffectScript.new()
	effect.type = effect_type
	effect.value = value
	effect.target_mode = target_mode
	effect.radius = radius
	effect.duration = duration
	return effect

static func make_class_config(attack_script: Script = null) -> ClassConfig:
	var config = ClassConfigScript.new()
	config.attack_script = attack_script
	return config

static func make_room(
	room_id: String,
	tier: int = 0,
	connections: Array[String] = [],
	room_type: int = 0,
	arena_scene_path: String = "res://scenes/levels/test_arena.tscn"
) -> Resource:
	var room = RoomDataScript.new()
	room.room_id = room_id
	room.tier = tier
	room.connections = connections
	room.room_type = room_type
	room.arena_scene_path = arena_scene_path
	return room

static func _make_named_child(script: Script, node_name: String) -> Node:
	var node: Node = script.new() as Node
	node.name = node_name
	return node

static func _make_collision_shape(node_name: String) -> CollisionShape2D:
	var shape := CollisionShape2D.new()
	shape.name = node_name
	shape.shape = CircleShape2D.new()
	return shape
