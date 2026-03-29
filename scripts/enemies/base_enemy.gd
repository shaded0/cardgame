extends CharacterBody2D

enum State { IDLE, CHASE, ATTACK, HURT, DEAD }

## Base enemy controller used by spawn system.
## Uses a small state machine and shared animation/health/hitbox components.
## Supports composable behavior scripts attached as child nodes via EnemyData.

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
var use_ranged_attack: bool = false
var _attack_sequence_id: int = 0

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health_component: HealthComponent = $HealthComponent
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var debuff_system: Node = $DebuffSystem

func _ready() -> void:
	add_to_group("enemies")

	hitbox_shape.disabled = true

	_setup_sprite()

	# Drop shadow beneath enemy
	var shadow := Sprite2D.new()
	shadow.texture = PlaceholderSprites.create_shadow_texture(30, 12)
	shadow.offset = Vector2(0, 2)
	shadow.z_index = -2
	shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(shadow)

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

		# Apply visual scale (e.g. golem boss is larger)
		if enemy_data.visual_scale != 1.0:
			anim_sprite.scale = Vector2(enemy_data.visual_scale, enemy_data.visual_scale)

		# Instantiate behavior scripts as child nodes
		for script in enemy_data.behavior_scripts:
			if script:
				var behavior := Node.new()
				behavior.set_script(script)
				behavior.name = script.resource_path.get_file().get_basename().to_pascal_case()
				add_child(behavior)

	hitbox.damage = attack_damage

	# Resolve player reference one frame later, after player node is fully ready.
	await get_tree().process_frame
	player = GameManager.get_player()

func _setup_sprite() -> void:
	var enemy_type := "slime"
	if enemy_data:
		enemy_type = enemy_data.enemy_type

	match enemy_type:
		"skeleton":
			anim_sprite.sprite_frames = SpriteAnimator.create_skeleton_frames()
			anim_sprite.offset = Vector2(0, -24)
		"fire_imp":
			anim_sprite.sprite_frames = SpriteAnimator.create_imp_frames()
			anim_sprite.offset = Vector2(0, -16)
		"shadow_wraith":
			anim_sprite.sprite_frames = SpriteAnimator.create_wraith_frames()
			anim_sprite.offset = Vector2(0, -26)
			modulate.a = 0.7
		"golem_boss":
			anim_sprite.sprite_frames = SpriteAnimator.create_golem_frames()
			anim_sprite.offset = Vector2(0, -28)
		_:
			anim_sprite.sprite_frames = SpriteAnimator.create_slime_frames(Color(0.4, 0.8, 0.3, 1.0))
			anim_sprite.offset = Vector2(0, -18)

	anim_sprite.play(&"idle")

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	if player == null or not is_instance_valid(player):
		return

	# Let behavior scripts override the frame (e.g. flee, teleport)
	if _run_behaviors(delta):
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

func _run_behaviors(delta: float) -> bool:
	## Iterate behavior children. If any returns true from before_physics(), it consumed the frame.
	for child in get_children():
		if child.has_method("before_physics"):
			if child.call("before_physics", self, delta):
				return true
	return false

func _get_behavior_damage_reduction() -> float:
	## Check behavior children for damage reduction (e.g. skeleton block).
	for child in get_children():
		if child.has_method("get_damage_reduction"):
			var reduction: float = child.call("get_damage_reduction")
			if reduction > 0.0:
				return reduction
	return 0.0

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
	_attack_sequence_id += 1
	var attack_id: int = _attack_sequence_id

	# Ranged enemies fire projectiles instead of using the melee hitbox
	if use_ranged_attack:
		_play_anim(&"attack")
		for child in get_children():
			if child.has_method("do_ranged_attack"):
				child.call("do_ranged_attack", self)
		_finish_attack_after(0.3, attack_id)
		return

	hitbox_shape.disabled = false
	hitbox.reset_targets()
	hitbox.damage = attack_damage * _get_attack_multiplier()
	hitbox.position = (player.global_position - global_position).normalized() * 36.0
	_play_anim(&"attack")

	_finish_attack_after(0.3, attack_id)

func _finish_attack_after(delay: float, attack_id: int) -> void:
	if not is_inside_tree():
		return
	var timer: SceneTreeTimer = get_tree().create_timer(delay)
	timer.timeout.connect(func() -> void:
		if not is_instance_valid(self) or current_state == State.DEAD or attack_id != _attack_sequence_id:
			return
		_disable_attack_hitbox()
		current_state = State.CHASE

		if not is_inside_tree():
			return
		var cd: SceneTreeTimer = get_tree().create_timer(attack_cooldown)
		cd.timeout.connect(func() -> void:
			if is_instance_valid(self) and attack_id == _attack_sequence_id and current_state != State.DEAD:
				can_attack = true
		)
	)

func _on_received_hit(incoming_hitbox: Hitbox) -> void:
	if current_state == State.DEAD:
		return

	# Apply Vulnerable debuff multiplier to incoming damage.
	var final_damage: float = incoming_hitbox.damage * _get_damage_multiplier()

	# Apply behavior-based damage reduction (e.g. skeleton block)
	var behavior_dr := _get_behavior_damage_reduction()
	if behavior_dr > 0.0:
		final_damage *= (1.0 - behavior_dr)
		DamageNumber.spawn_text(get_parent(), global_position + Vector2(0, -30), "BLOCKED", Color(0.5, 0.7, 1.0))

	health_component.take_damage(final_damage)
	if current_state == State.DEAD:
		return

	# Floating damage number + white flash + sparks
	DamageNumber.spawn(get_parent(), global_position, final_damage, Color(1.0, 1.0, 1.0))
	ScreenFX.spawn_hit_sparks(get_parent(), global_position, 4, Color(1.0, 0.8, 0.3))
	ScreenFX.shake(self, 4.0, 0.08)

	modulate = Color(3, 3, 3, 1)
	if is_inside_tree():
		var flash_timer: SceneTreeTimer = get_tree().create_timer(0.08)
		flash_timer.timeout.connect(func() -> void:
			if is_instance_valid(self):
				_restore_modulate()
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

func _restore_modulate() -> void:
	## Reset modulate, respecting wraith transparency.
	if enemy_data and enemy_data.enemy_type == "shadow_wraith":
		modulate = Color(1, 1, 1, 0.7)
	else:
		modulate = Color(1, 1, 1, 1)

func _on_died() -> void:
	current_state = State.DEAD
	_attack_sequence_id += 1
	# Disable all combat interactions immediately.
	_disable_attack_hitbox()
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

func spawn_minion(minion_data: EnemyData, offset: Vector2) -> void:
	## Spawns a new enemy as a minion (used by boss behaviors).
	var scene: PackedScene = preload("res://scenes/enemies/base_enemy.tscn")
	var minion: Node2D = scene.instantiate() as Node2D
	if minion == null:
		return
	minion.set("enemy_data", minion_data)
	minion.global_position = global_position + offset
	var parent: Node = get_parent()
	if parent == null:
		return
	parent.add_child(minion)

func _disable_attack_hitbox() -> void:
	if is_instance_valid(hitbox_shape):
		hitbox_shape.set_deferred("disabled", true)
	if is_instance_valid(hitbox):
		hitbox.position = Vector2.ZERO

func _get_attack_multiplier() -> float:
	if debuff_system and debuff_system.has_method("get_attack_multiplier"):
		return float(debuff_system.call("get_attack_multiplier"))
	return 1.0

func _get_damage_multiplier() -> float:
	if debuff_system and debuff_system.has_method("get_damage_multiplier"):
		return float(debuff_system.call("get_damage_multiplier"))
	return 1.0
