extends CharacterBody2D

enum State { IDLE, CHASE, ATTACK, HURT, DEAD }

@export var enemy_data: Resource  # EnemyData

var current_state: State = State.IDLE
var move_speed: float = 60.0
var attack_damage: float = 8.0
var attack_range: float = 20.0
var attack_cooldown: float = 1.5
var chase_range: float = 200.0
var can_attack: bool = true
var player: CharacterBody2D = null

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox
@onready var health_component: HealthComponent = $HealthComponent
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D

func _ready() -> void:
	add_to_group("enemies")
	hitbox_shape.disabled = true

	# Animated slime sprite
	anim_sprite.sprite_frames = SpriteAnimator.create_slime_frames(Color(0.4, 0.8, 0.3, 1.0))
	anim_sprite.offset = Vector2(0, -18)
	anim_sprite.play(&"idle")

	if enemy_data:
		move_speed = enemy_data.move_speed
		attack_damage = enemy_data.attack_damage
		attack_range = enemy_data.attack_range
		attack_cooldown = enemy_data.attack_cooldown
		chase_range = enemy_data.chase_range
		health_component.max_health = enemy_data.max_health
		health_component.current_health = enemy_data.max_health
		hitbox.damage = attack_damage

	health_component.died.connect(_on_died)
	hurtbox.received_hit.connect(_on_received_hit)

	# Find player
	await get_tree().process_frame
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0] as CharacterBody2D

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	if player == null:
		return

	var distance: float = global_position.distance_to(player.global_position)

	match current_state:
		State.IDLE:
			_play_anim(&"idle")
			if distance <= chase_range:
				current_state = State.CHASE
		State.CHASE:
			_play_anim(&"run")
			_chase_player(delta)
			if distance <= attack_range and can_attack:
				current_state = State.ATTACK
				_do_attack()
			elif distance > chase_range:
				current_state = State.IDLE
				velocity = Vector2.ZERO
		State.ATTACK:
			pass
		State.HURT:
			pass

func _play_anim(anim_name: StringName) -> void:
	if anim_sprite.animation != anim_name:
		if anim_sprite.sprite_frames.has_animation(anim_name):
			anim_sprite.play(anim_name)

func _chase_player(_delta: float) -> void:
	var direction: Vector2 = (player.global_position - global_position).normalized()
	velocity = direction * move_speed

	# Rotate sprite to face player
	anim_sprite.rotation = direction.angle() + PI / 2.0

	move_and_slide()

func _do_attack() -> void:
	can_attack = false
	hitbox_shape.disabled = false
	hitbox.position = (player.global_position - global_position).normalized() * 36.0
	_play_anim(&"attack")

	var timer: SceneTreeTimer = get_tree().create_timer(0.3)
	timer.timeout.connect(func() -> void:
		hitbox_shape.disabled = true
		hitbox.position = Vector2.ZERO
		current_state = State.CHASE

		var cd: SceneTreeTimer = get_tree().create_timer(attack_cooldown)
		cd.timeout.connect(func() -> void: can_attack = true)
	)

func _on_received_hit(incoming_hitbox: Hitbox) -> void:
	health_component.take_damage(incoming_hitbox.damage)

	DamageNumber.spawn(get_parent(), global_position, incoming_hitbox.damage, Color(1.0, 1.0, 1.0))

	modulate = Color(3, 3, 3, 1)
	var flash_timer: SceneTreeTimer = get_tree().create_timer(0.08)
	flash_timer.timeout.connect(func() -> void: modulate = Color(1, 1, 1, 1))

	var knockback_dir: Vector2 = (global_position - incoming_hitbox.global_position).normalized()
	velocity = knockback_dir * 360.0

	current_state = State.HURT
	var hurt_timer: SceneTreeTimer = get_tree().create_timer(0.15)
	hurt_timer.timeout.connect(func() -> void:
		if current_state != State.DEAD:
			current_state = State.CHASE
	)

func _on_died() -> void:
	current_state = State.DEAD
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
