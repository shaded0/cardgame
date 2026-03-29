extends CharacterBody2D

enum State { IDLE, CHASE, ATTACK, HURT, DEAD }

## Base enemy controller used by spawn system.
## Uses a small state machine and shared animation/health/hitbox components.

@export var enemy_data: EnemyData

## Runtime state + tunables copied from EnemyData at `_ready()`.
var current_state: State = State.IDLE
var move_speed: float = 60.0
var attack_damage: float = 8.0
var attack_range: float = 20.0
var attack_cooldown: float = 1.5
var chase_range: float = 200.0
var can_attack: bool = true
var player: CharacterBody2D = null

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health_component: HealthComponent = $HealthComponent
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D

func _ready() -> void:
	add_to_group("enemies")

	hitbox_shape.disabled = true

	anim_sprite.sprite_frames = SpriteAnimator.create_slime_frames(Color(0.4, 0.8, 0.3, 1.0))
	anim_sprite.offset = Vector2(0, -18)
	anim_sprite.play(&"idle")

	health_component.died.connect(_on_died)
	hurtbox.received_hit.connect(_on_received_hit)

	if enemy_data:
		move_speed = enemy_data.move_speed
		attack_damage = enemy_data.attack_damage
		attack_range = enemy_data.attack_range
		attack_cooldown = enemy_data.attack_cooldown
		chase_range = enemy_data.chase_range
		health_component.max_health = enemy_data.max_health
		health_component.reset_to_full()

	hitbox.damage = attack_damage

	# Resolve player reference one frame later, after player node is fully ready.
	await get_tree().process_frame
	player = GameManager.get_player()

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	if player == null or not is_instance_valid(player):
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
			_play_anim(&"idle")
			move_and_slide()
			velocity = velocity.lerp(Vector2.ZERO, min(delta * 10.0, 1.0))

func _play_anim(anim_name: StringName) -> void:
	if anim_sprite.animation != anim_name:
		if anim_sprite.sprite_frames.has_animation(anim_name):
			anim_sprite.play(anim_name)

func _chase_player(_delta: float) -> void:
	var direction: Vector2 = (player.global_position - global_position).normalized()
	velocity = direction * move_speed
	anim_sprite.rotation = direction.angle() + PI / 2.0
	move_and_slide()

func _do_attack() -> void:
	can_attack = false
	hitbox_shape.disabled = false
	hitbox.reset_targets()
	hitbox.position = (player.global_position - global_position).normalized() * 36.0
	_play_anim(&"attack")

	if not is_inside_tree():
		return
	var timer: SceneTreeTimer = get_tree().create_timer(0.3)
	timer.timeout.connect(func() -> void:
		if not is_instance_valid(self) or current_state == State.DEAD:
			return
		hitbox_shape.disabled = true
		hitbox.position = Vector2.ZERO
		current_state = State.CHASE

		if not is_inside_tree():
			return
		var cd: SceneTreeTimer = get_tree().create_timer(attack_cooldown)
		cd.timeout.connect(func() -> void:
			if is_instance_valid(self):
				can_attack = true
		)
	)

func _on_received_hit(incoming_hitbox: Hitbox) -> void:
	if current_state == State.DEAD:
		return

	health_component.take_damage(incoming_hitbox.damage)
	if current_state == State.DEAD:
		return

	# Floating damage number + white flash + sparks
	DamageNumber.spawn(get_parent(), global_position, incoming_hitbox.damage, Color(1.0, 1.0, 1.0))
	ScreenFX.spawn_hit_sparks(get_parent(), global_position, 4, Color(1.0, 0.8, 0.3))
	ScreenFX.shake(self, 4.0, 0.08)

	modulate = Color(3, 3, 3, 1)
	if is_inside_tree():
		var flash_timer: SceneTreeTimer = get_tree().create_timer(0.08)
		flash_timer.timeout.connect(func() -> void:
			if is_instance_valid(self):
				modulate = Color(1, 1, 1, 1)
		)

	var knockback_dir: Vector2 = (global_position - incoming_hitbox.global_position).normalized()
	velocity = knockback_dir * 360.0

	current_state = State.HURT
	if is_inside_tree():
		var hurt_timer: SceneTreeTimer = get_tree().create_timer(0.15)
		hurt_timer.timeout.connect(func() -> void:
			if is_instance_valid(self) and current_state != State.DEAD:
				current_state = State.CHASE
		)

func _on_died() -> void:
	current_state = State.DEAD
	# Disable all combat interactions immediately.
	hitbox_shape.disabled = true
	hurtbox.is_invincible = true
	var hurtbox_shape: CollisionShape2D = hurtbox.get_node_or_null("CollisionShape2D")
	if hurtbox_shape:
		hurtbox_shape.set_deferred("disabled", true)

	# Death burst effect
	ScreenFX.spawn_hit_sparks(get_parent(), global_position, 10, Color(1.0, 0.6, 0.2))
	ScreenFX.spawn_ground_crack(get_parent(), global_position, 25.0)
	ScreenFX.shake(self, 6.0, 0.15)
	SpellEffectVisual.spawn_burst(get_parent(), global_position, 18.0, Color(1.0, 0.5, 0.2, 0.5), 0.35)

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_property(self, "scale", Vector2(1.3, 0.5), 0.3).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)
