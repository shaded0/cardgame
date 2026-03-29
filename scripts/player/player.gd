extends CharacterBody2D

# Stats (will be set by ClassConfig)
@export var move_speed: float = 420.0
@export var dodge_speed: float = 840.0
@export var dodge_duration: float = 0.4
@export var dodge_cooldown: float = 0.8
@export var attack_duration: float = 0.4
@export var attack_damage: float = 20.0

var facing_direction: Vector2 = Vector2(1, 0.5).normalized()
var can_dodge: bool = true
var current_attack: Node = null
var attack_visual: Sprite2D = null
var current_anim: StringName = &"idle"

## Core player node with multiple components:
## - hitbox/hurtbox (combat)
## - health/mana (resources)
## - state machine (movement/attack/dodge)
## - attack behavior plugin by class

@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var mana_component: ManaComponent = $ManaComponent
@onready var card_manager: CardManager = $CardManager

func _ready() -> void:
	# Start with disabled melee hitbox; each attack enables it on demand.
	hitbox_shape.disabled = true

	_setup_animated_sprite()

	# Create attack visual indicator
	attack_visual = Sprite2D.new()
	attack_visual.visible = false
	attack_visual.z_index = -1
	add_child(attack_visual)

	# Wire mana generation signals
	hitbox.hit_landed.connect(func(_hurtbox: Area2D) -> void: mana_component.on_basic_attack_hit())
	hurtbox.received_hit.connect(func(hb: Hitbox) -> void:
		health_component.take_damage(hb.damage)
		mana_component.on_damage_taken()
		_flash_hurt()
	)

	# Initialize with class config if available
	var config: Resource = GameManager.current_class_config
	if config:
		apply_class_config(config)

func _setup_animated_sprite() -> void:
	# Player visual is generated at runtime so class selection can swap colors/weapons instantly.
	var config: Resource = GameManager.current_class_config
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

func _process(_delta: float) -> void:
	# Always face toward the mouse cursor
	var mouse_pos: Vector2 = get_global_mouse_position()
	var to_mouse: Vector2 = (mouse_pos - global_position)
	if to_mouse.length() > 2.0:
		facing_direction = to_mouse.normalized()
		anim_sprite.rotation = facing_direction.angle() + PI / 2.0

func play_anim(anim_name: StringName) -> void:
	# Guard avoids restarting current animation and causing jitter.
	if current_anim != anim_name:
		current_anim = anim_name
		if anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation(anim_name):
			anim_sprite.play(anim_name)

func apply_class_config(config: Resource) -> void:
	# Copy tuned values from ClassConfig into runtime component properties.
	move_speed = config.move_speed
	dodge_speed = config.dodge_speed
	dodge_duration = config.dodge_duration
	attack_damage = config.attack_damage
	attack_duration = config.attack_duration
	health_component.max_health = config.max_health
	health_component.reset_to_full()
	mana_component.max_mana = config.max_mana
	mana_component.current_mana = 0.0
	mana_component.mana_changed.emit(mana_component.current_mana, mana_component.max_mana)
	mana_component.mana_per_hit_dealt = config.mana_per_hit_dealt
	mana_component.mana_per_hit_taken = config.mana_per_hit_taken
	hitbox.damage = config.attack_damage

	# Setup attack visual color based on class
	var atk_color := Color(1, 1, 0.5, 0.6)
	match config.class_id:
		&"soldier": atk_color = Color(0.8, 0.8, 1.0, 0.5)
		&"rogue": atk_color = Color(0.5, 1.0, 0.5, 0.5)
		&"mage": atk_color = Color(0.7, 0.4, 1.0, 0.5)
	attack_visual.texture = PlaceholderSprites.create_circle_texture(30, atk_color)

	# Load basic attack script
	if current_attack and is_instance_valid(current_attack):
		current_attack.queue_free()
		current_attack = null

	if config.attack_script:
		var attack_node := Node.new()
		attack_node.set_script(config.attack_script)
		attack_node.name = "BasicAttack"
		add_child(attack_node)
		current_attack = attack_node
		if current_attack.has_method("get_attack_duration"):
			attack_duration = current_attack.get_attack_duration()

	# Initialize card deck
	if config.card_pool.size() > 0:
		card_manager.initialize_deck(config.card_pool)

func get_iso_input() -> Vector2:
	# Convert top-down movement keys to isometric axis to match sprite movement feel.
	var raw: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if raw.length() < 0.1:
		return Vector2.ZERO
	var iso := Vector2(
		raw.x - raw.y,
		(raw.x + raw.y) * 0.5
	)
	return iso.normalized()

func update_facing(_direction: Vector2) -> void:
	# Reserved hook: can rotate/flip sprites if your character mesh needs explicit facing logic.
	pass

func get_aim_direction() -> Vector2:
	# Aiming is cursor-based in this prototype; fallback to last facing vector when mouse overlaps player.
	var mouse_pos: Vector2 = get_global_mouse_position()
	var dir: Vector2 = (mouse_pos - global_position)
	if dir.length() < 1.0:
		return facing_direction
	return dir.normalized()

func start_attack() -> void:
	# Start one hit window and let basic-attack script define exact collider movement.
	var aim: Vector2 = get_aim_direction()
	play_anim(&"attack")

	if attack_visual:
		attack_visual.position = aim * 55.0
		attack_visual.visible = true

	if current_attack and current_attack.has_method("execute"):
		current_attack.execute(self, aim)
	else:
		hitbox_shape.disabled = false
		hitbox.position = aim * 60.0

func end_attack() -> void:
	# Always stop attack visuals and collider offsets in one place.
	if attack_visual:
		attack_visual.visible = false
	play_anim(&"idle")

	if current_attack and current_attack.has_method("end_attack"):
		current_attack.end_attack(self)
	else:
		hitbox_shape.disabled = true
		hitbox.position = Vector2.ZERO

func set_invincible(value: bool) -> void:
	# Keep dodge immunity in the hurtbox script instead of relying on scene-monitoring side effects.
	hurtbox.is_invincible = value

func start_dodge_cooldown() -> void:
	# Start a one-shot timer so dodge can only trigger again after cooldown.
	var timer: SceneTreeTimer = get_tree().create_timer(dodge_cooldown)
	timer.timeout.connect(func() -> void: can_dodge = true)

func _flash_hurt() -> void:
	# Small red flash for quick damage feedback.
	modulate = Color(1.5, 0.5, 0.5, 1.0)
	var timer: SceneTreeTimer = get_tree().create_timer(0.1)
	timer.timeout.connect(func() -> void: modulate = Color(1, 1, 1, 1))
