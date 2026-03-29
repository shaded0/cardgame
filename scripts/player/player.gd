class_name PlayerController
extends CharacterBody2D

const DODGE_AFTERIMAGE_FX_TAG := "dodge_afterimage"

# Stats (will be set by ClassConfig)
@export var move_speed: float = 420.0
@export var dodge_speed: float = 840.0
@export var dodge_duration: float = 0.4
@export var dodge_cooldown: float = 0.8
@export var attack_duration: float = 0.4
@export var attack_damage: float = 20.0

## Movement feel tuning — acceleration uses curved ramp for snappy-but-weighty feel.
@export var acceleration: float = 2600.0  ## Units/s² toward max speed
@export var deceleration: float = 3600.0  ## Units/s² when releasing input (tighter than accel)
@export var turn_decel_multiplier: float = 1.85  ## Extra decel when reversing direction
@export var move_input_deadzone: float = 0.12
@export var move_intent_grace: float = 0.08
@export var unstuck_threshold_time: float = 0.14
@export var unstuck_min_speed: float = 90.0
@export var unstuck_max_displacement_per_second: float = 24.0
@export var unstuck_nudge_distance: float = 4.0
@export var unstuck_cooldown: float = 0.12

## Base stats stored so buffs can add/remove from a known baseline.
var base_move_speed: float = 420.0
var base_dodge_speed: float = 840.0
var base_dodge_cooldown: float = 0.8

var facing_direction: Vector2 = Vector2(1, 0.5).normalized()
var can_dodge: bool = true
var current_attack: Node = null
var attack_visual: Sprite2D = null
var current_anim: StringName = &"idle"
var _attack_active: bool = false
var _attack_elapsed: float = 0.0
var _move_input: Vector2 = Vector2.ZERO
var _last_move_direction: Vector2 = Vector2(1, 0.5).normalized()
var _move_intent_remaining: float = 0.0
var _movement_input_override_active: bool = false
var _movement_input_override: Vector2 = Vector2.ZERO
var _last_motion_position: Vector2 = Vector2.ZERO
var _stuck_time: float = 0.0
var _unstuck_cooldown_remaining: float = 0.0

## Core player node with components:
## - hitbox/hurtbox (combat)
## - health/mana (resources)
## - buff_system (stat modifiers)
## - state machine (movement/attack/dodge)
## - attack behavior plugin by class

@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var mana_component: ManaComponent = $ManaComponent
@onready var card_manager: CardManager = $CardManager
@onready var buff_system: BuffSystem = $BuffSystem
@onready var state_machine: PlayerStateMachine = $StateMachine

func _ready() -> void:
	_refresh_combat_refs()
	update_movement_input(0.0)
	_last_motion_position = global_position
	# Start with disabled melee hitbox; each attack enables it on demand.
	hitbox_shape.disabled = true

	_setup_animated_sprite()
	_setup_shadow()

	# Create attack visual indicator
	attack_visual = Sprite2D.new()
	attack_visual.visible = false
	attack_visual.z_index = -1
	add_child(attack_visual)

	# Wire combat signals
	_bind_combat_signals()

	# Initialize with class config if available
	var config: ClassConfig = GameManager.current_class_config
	if config:
		apply_class_config(config)
	_log_attack("ready", {"class": GameManager.current_class_config.class_id if GameManager.current_class_config else "none"})

func _on_player_hit(hb: Hitbox) -> void:
	## Central damage handler: applies buff reductions, knockback, mana gain.
	if not is_instance_valid(health_component) or not is_instance_valid(mana_component):
		return

	# Route incoming damage through buff system for defense reductions.
	var final_damage: float = hb.damage
	if buff_system:
		final_damage = buff_system.get_damage_after_reduction(final_damage)

	health_component.take_damage(final_damage)
	mana_component.on_damage_taken()

	# Show damage number on player
	DamageNumber.spawn(get_parent(), global_position, final_damage, Color(1.0, 0.3, 0.3))

	# Knockback away from the hit source
	if is_instance_valid(hb):
		var kb_dir: Vector2 = (global_position - hb.global_position).normalized()
		velocity = kb_dir * 300.0

	# Screen shake, sparks, and flash on hit
	ScreenFX.shake(self, 6.0, 0.12)
	ScreenFX.spawn_hit_sparks(get_parent(), global_position, 5, Color(1.0, 0.4, 0.3))
	ScreenFX.flash(self, Color(1.0, 0.2, 0.1, 0.15), 0.08)

	# Scale punch on hit
	var punch := create_tween()
	punch.tween_property(anim_sprite, "scale", Vector2(1.12, 0.88), 0.04)
	punch.tween_property(anim_sprite, "scale", Vector2(0.95, 1.05), 0.04)
	punch.tween_property(anim_sprite, "scale", Vector2(1.0, 1.0), 0.04)

	_flash_hurt()

func _on_attack_hit(_hurtbox: Area2D) -> void:
	## Feedback when the player's attack connects: hitstop, shake, mana.
	mana_component.on_basic_attack_hit()
	# Brief hitstop for impact weight
	hitbox._do_hit_stop()
	# Small shake so attacks feel punchy from the attacker side
	ScreenFX.shake(self, 3.0, 0.06)

func _setup_shadow() -> void:
	var shadow := Sprite2D.new()
	shadow.texture = PlaceholderSprites.create_shadow_texture(40, 16)
	shadow.offset = Vector2(0, 4)
	shadow.z_index = -2
	shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(shadow)

func _setup_animated_sprite() -> void:
	var config: ClassConfig = GameManager.current_class_config
	var body_color := Color(0.35, 0.45, 0.6, 1.0)
	var detail_color := Color(0.5, 0.55, 0.65, 1.0)
	var weapon := "sword"
	if config:
		match config.class_id:
			&"soldier":
				body_color = Color(0.35, 0.4, 0.55, 1.0)
				detail_color = Color(0.55, 0.6, 0.7, 1.0)
				weapon = "sword"
			&"rogue":
				body_color = Color(0.2, 0.35, 0.25, 1.0)
				detail_color = Color(0.3, 0.5, 0.35, 1.0)
				weapon = "daggers"
			&"mage":
				body_color = Color(0.3, 0.2, 0.45, 1.0)
				detail_color = Color(0.5, 0.3, 0.7, 1.0)
				weapon = "staff"

	anim_sprite.sprite_frames = SpriteAnimator.create_humanoid_frames(body_color, detail_color, weapon)
	anim_sprite.offset = Vector2(0, -24)
	anim_sprite.play(&"idle")

	# Apply outline shader for readability against dark floors
	var outline_shader: Shader = load("res://shaders/sprite_outline.gdshader")
	if outline_shader:
		var mat := ShaderMaterial.new()
		mat.shader = outline_shader
		anim_sprite.material = mat

func _process(_delta: float) -> void:
	# Always face toward the mouse cursor
	var mouse_pos: Vector2 = get_global_mouse_position()
	var to_mouse: Vector2 = (mouse_pos - global_position)
	if to_mouse.length() > 2.0:
		facing_direction = to_mouse.normalized()
		anim_sprite.rotation = facing_direction.angle() + PI / 2.0

func _physics_process(delta: float) -> void:
	_update_attack_watchdog(delta)

func report_motion_step(delta: float) -> void:
	if _unstuck_cooldown_remaining > 0.0:
		_unstuck_cooldown_remaining = maxf(_unstuck_cooldown_remaining - delta, 0.0)

	var displacement: float = global_position.distance_to(_last_motion_position)
	_last_motion_position = global_position

	if not has_move_intent() or velocity.length() < unstuck_min_speed:
		_stuck_time = 0.0
		return

	var collision_count: int = get_slide_collision_count()
	if collision_count <= 0:
		_stuck_time = 0.0
		return

	var moved_enough: bool = displacement > unstuck_max_displacement_per_second * delta
	if moved_enough:
		_stuck_time = 0.0
		return

	_stuck_time += delta
	if _stuck_time < unstuck_threshold_time or _unstuck_cooldown_remaining > 0.0:
		return

	_try_unstuck(collision_count)

func _try_unstuck(collision_count: int) -> void:
	var collision_normals: Array[Vector2] = []
	for i in range(collision_count):
		var collision := get_slide_collision(i)
		if collision:
			collision_normals.append(collision.get_normal())

	var escape_dir := compute_unstuck_direction(collision_normals, get_move_direction())
	if escape_dir == Vector2.ZERO:
		return

	global_position += escape_dir * unstuck_nudge_distance
	velocity = velocity.slide(escape_dir)
	_stuck_time = 0.0
	_unstuck_cooldown_remaining = unstuck_cooldown
	_log_attack("movement_unstuck", {"dir": escape_dir, "collisions": collision_count})

static func compute_unstuck_direction(collision_normals: Array[Vector2], move_direction: Vector2) -> Vector2:
	var normal_sum := Vector2.ZERO
	for normal in collision_normals:
		if normal is Vector2 and normal.length() > 0.001:
			normal_sum += normal.normalized()

	if normal_sum.length() > 0.001:
		return normal_sum.normalized()
	if move_direction.length() > 0.001:
		return -move_direction.normalized()
	return Vector2.ZERO

func play_anim(anim_name: StringName) -> void:
	if current_anim != anim_name:
		current_anim = anim_name
		if anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation(anim_name):
			anim_sprite.play(anim_name)

func apply_class_config(config: ClassConfig) -> void:
	move_speed = config.move_speed
	dodge_speed = config.dodge_speed
	dodge_cooldown = config.dodge_cooldown
	dodge_duration = config.dodge_duration
	attack_damage = config.attack_damage
	attack_duration = config.attack_duration

	# Store base values for buff math
	base_move_speed = config.move_speed
	base_dodge_speed = config.dodge_speed
	base_dodge_cooldown = config.dodge_cooldown

	health_component.max_health = config.max_health
	health_component.reset_to_full()
	mana_component.max_mana = config.max_mana
	mana_component.mana_per_hit_dealt = config.mana_per_hit_dealt
	mana_component.mana_per_hit_taken = config.mana_per_hit_taken
	mana_component.initialize()
	hitbox.damage = config.attack_damage

	# Setup attack visual color based on class
	var atk_color := Color(1, 1, 0.5, 0.6)
	match config.class_id:
		&"soldier": atk_color = Color(0.8, 0.8, 1.0, 0.5)
		&"rogue": atk_color = Color(0.5, 1.0, 0.5, 0.5)
		&"mage": atk_color = Color(0.7, 0.4, 1.0, 0.5)
	attack_visual.texture = PlaceholderSprites.create_circle_texture(30, atk_color)

	# Load basic attack script
	_attack_active = false
	_attack_elapsed = 0.0
	_disable_attack_hitbox()
	_rebuild_attack_controller(config.attack_script)

	# Initialize card deck — use run_deck if available (accumulated cards), else starting pool.
	if GameManager.run_deck.size() > 0:
		card_manager.initialize_deck(GameManager.run_deck)
	elif config.card_pool.size() > 0:
		card_manager.initialize_deck(config.card_pool)

func get_iso_input() -> Vector2:
	return _move_input

func has_move_intent() -> bool:
	return _move_input != Vector2.ZERO or _move_intent_remaining > 0.0

func get_move_direction() -> Vector2:
	if _move_input != Vector2.ZERO:
		return _move_input.normalized()
	return _last_move_direction

func get_move_input_strength() -> float:
	return _move_input.length()

func get_last_move_direction() -> Vector2:
	return _last_move_direction

func update_movement_input(delta: float) -> void:
	var raw_input := _movement_input_override if _movement_input_override_active else Input.get_vector(
		"move_left", "move_right", "move_up", "move_down"
	)
	_move_input = _to_iso_input(raw_input, move_input_deadzone)
	if _move_input != Vector2.ZERO:
		_last_move_direction = _move_input.normalized()
		_move_intent_remaining = move_intent_grace
	else:
		_move_intent_remaining = maxf(_move_intent_remaining - delta, 0.0)

func set_movement_input_override(raw_input: Vector2) -> void:
	_movement_input_override_active = true
	_movement_input_override = raw_input.limit_length(1.0)

func clear_movement_input_override() -> void:
	_movement_input_override_active = false
	_movement_input_override = Vector2.ZERO

static func _to_iso_input(raw_input: Vector2, deadzone: float = 0.1) -> Vector2:
	if raw_input.length() < deadzone:
		return Vector2.ZERO
	var iso := Vector2(
		raw_input.x - raw_input.y,
		(raw_input.x + raw_input.y) * 0.5
	)
	if iso.length() < 0.001:
		return Vector2.ZERO
	return iso.normalized() * minf(raw_input.length(), 1.0)

func update_facing(_direction: Vector2) -> void:
	pass

func get_aim_direction() -> Vector2:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var dir: Vector2 = (mouse_pos - global_position)
	if dir.length() < 1.0:
		return facing_direction
	return dir.normalized()

func get_effective_damage() -> float:
	## Returns attack_damage modified by active buffs (empower, damage_up).
	if buff_system:
		return buff_system.get_modified_damage(attack_damage)
	return attack_damage

func start_attack() -> bool:
	_refresh_combat_refs()
	_bind_combat_signals()
	var aim: Vector2 = get_aim_direction()
	play_anim(&"attack")
	_attack_active = true
	_attack_elapsed = 0.0
	_log_attack("start_attack", {"aim": aim, "controller_valid": is_instance_valid(current_attack), "state": _get_state_name()})

	# Guard against freed hitbox during scene transitions.
	if not is_instance_valid(hitbox):
		_attack_active = false
		_disable_attack_hitbox()
		_log_attack("start_attack_failed_missing_hitbox")
		return false

	# Reset hitbox target tracking so each swing can hit enemies again.
	hitbox.reset_targets()

	if attack_visual:
		attack_visual.position = aim * 55.0
		attack_visual.visible = true

	# Apply buff-modified damage to hitbox for this swing.
	hitbox.damage = get_effective_damage()

	var attack_controller: Node = _ensure_attack_controller()
	if attack_controller and attack_controller.has_method("execute"):
		attack_controller.execute(self, aim)
		_log_attack("start_attack_executed", {"controller": attack_controller.name, "duration": attack_duration})
	elif attack_controller == null and GameManager.current_class_config and GameManager.current_class_config.attack_script:
		_attack_active = false
		_disable_attack_hitbox()
		_log_attack("start_attack_failed_missing_controller")
		return false
	else:
		if not enable_attack_hitbox(aim * 60.0):
			_attack_active = false
			_disable_attack_hitbox()
			_log_attack("start_attack_failed_enable_hitbox")
			return false
		_log_attack("start_attack_fallback_melee", {"duration": attack_duration})
	return true

func end_attack() -> void:
	_log_attack("end_attack", {"elapsed": snapped(_attack_elapsed, 0.001), "state": _get_state_name()})
	_attack_active = false
	_attack_elapsed = 0.0
	if attack_visual:
		attack_visual.visible = false
	play_anim(&"idle")

	var attack_controller: Node = _ensure_attack_controller(false)
	if attack_controller and attack_controller.has_method("end_attack"):
		attack_controller.end_attack(self)
	else:
		_disable_attack_hitbox()

func set_invincible(value: bool) -> void:
	hurtbox.is_invincible = value

func start_dodge_cooldown() -> void:
	var timer: SceneTreeTimer = get_tree().create_timer(dodge_cooldown)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(self):
			can_dodge = true
	)

func _flash_hurt() -> void:
	modulate = Color(1.5, 0.5, 0.5, 1.0)
	var timer: SceneTreeTimer = get_tree().create_timer(0.1)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(self):
			modulate = Color(1, 1, 1, 1)
	)

func force_end_attack() -> void:
	## Hard stop used by watchdog/self-healing paths when attack state desyncs.
	_log_attack("force_end_attack", {"elapsed": snapped(_attack_elapsed, 0.001), "state": _get_state_name()})
	_attack_active = false
	_attack_elapsed = 0.0
	if attack_visual:
		attack_visual.visible = false
	_disable_attack_hitbox()
	clear_tracked_fx(DODGE_AFTERIMAGE_FX_TAG)
	if state_machine and state_machine.is_in_state("attack"):
		state_machine.recover_to_neutral()

func _update_attack_watchdog(delta: float) -> void:
	if not _attack_active:
		return

	_attack_elapsed += delta
	var attack_timeout: float = maxf(attack_duration + 0.2, 0.3)
	if _attack_elapsed < attack_timeout:
		return

	# If we stayed "attacking" longer than expected, clear combat state so input can recover.
	_log_attack("watchdog_timeout", {"elapsed": snapped(_attack_elapsed, 0.001), "timeout": attack_timeout, "state": _get_state_name()})
	force_end_attack()

func _ensure_attack_controller(rebuild_if_missing: bool = true) -> Node:
	if is_instance_valid(current_attack):
		return current_attack

	_log_attack("missing_attack_controller", {"rebuild": rebuild_if_missing})
	current_attack = null
	if not rebuild_if_missing:
		return null
	if GameManager.current_class_config == null:
		return null
	return _rebuild_attack_controller(GameManager.current_class_config.attack_script)

func _rebuild_attack_controller(attack_script: Script) -> Node:
	if current_attack and is_instance_valid(current_attack):
		current_attack.queue_free()
	current_attack = null

	if attack_script == null:
		_log_attack("rebuild_attack_controller_skipped")
		return null

	var attack_node := Node.new()
	attack_node.set_script(attack_script)
	attack_node.name = "BasicAttack"
	add_child(attack_node)
	current_attack = attack_node
	if current_attack.has_method("get_attack_duration"):
		attack_duration = current_attack.get_attack_duration()
	_log_attack("rebuild_attack_controller", {"controller": current_attack.name, "duration": attack_duration})
	return current_attack

func _disable_attack_hitbox() -> void:
	_refresh_combat_refs()
	if is_instance_valid(hitbox_shape):
		hitbox_shape.set_deferred("disabled", true)
	if is_instance_valid(hitbox):
		hitbox.position = Vector2.ZERO

func disable_attack_hitbox() -> void:
	_disable_attack_hitbox()

func enable_attack_hitbox(offset: Vector2, damage: float = -1.0) -> bool:
	_refresh_combat_refs()
	if not is_instance_valid(hitbox) or not is_instance_valid(hitbox_shape):
		return false
	if damage >= 0.0:
		hitbox.damage = damage
	hitbox.position = offset
	hitbox_shape.set_deferred("disabled", false)
	return true

func _refresh_combat_refs() -> void:
	if not is_instance_valid(hitbox):
		hitbox = get_node_or_null("Hitbox") as Hitbox
	if not is_instance_valid(hurtbox):
		hurtbox = get_node_or_null("Hurtbox") as Hurtbox
	if not is_instance_valid(anim_sprite):
		anim_sprite = get_node_or_null("AnimatedSprite") as AnimatedSprite2D
	if not is_instance_valid(hitbox_shape):
		hitbox_shape = get_node_or_null("Hitbox/CollisionShape2D") as CollisionShape2D
	if not is_instance_valid(health_component):
		health_component = get_node_or_null("HealthComponent") as HealthComponent
	if not is_instance_valid(mana_component):
		mana_component = get_node_or_null("ManaComponent") as ManaComponent
	if not is_instance_valid(card_manager):
		card_manager = get_node_or_null("CardManager") as CardManager
	if not is_instance_valid(buff_system):
		buff_system = get_node_or_null("BuffSystem") as BuffSystem
	if not is_instance_valid(state_machine):
		state_machine = get_node_or_null("StateMachine") as PlayerStateMachine

func _bind_combat_signals() -> void:
	if is_instance_valid(hitbox) and not hitbox.hit_landed.is_connected(_on_attack_hit):
		hitbox.hit_landed.connect(_on_attack_hit)
	if is_instance_valid(hurtbox) and not hurtbox.received_hit.is_connected(_on_player_hit):
		hurtbox.received_hit.connect(_on_player_hit)

func clear_tracked_fx(fx_tag: String = "") -> void:
	var parent := get_parent()
	if parent == null or not is_instance_valid(parent):
		return

	var removed_count := 0
	for child in parent.get_children():
		if not (child is CanvasItem):
			continue
		if child.get_meta("fx_owner_id", -1) != get_instance_id():
			continue
		if not fx_tag.is_empty() and child.get_meta("fx_tag", "") != fx_tag:
			continue
		child.queue_free()
		removed_count += 1

	if removed_count > 0:
		_log_attack("clear_tracked_fx", {"tag": fx_tag if not fx_tag.is_empty() else "all", "count": removed_count})

func _get_state_name() -> String:
	if state_machine == null or state_machine.current_state == null:
		return "none"
	return state_machine.current_state.name.to_lower()

func _log_attack(event: String, details: Dictionary = {}) -> void:
	GameManager.log_attack("player", event, details)
