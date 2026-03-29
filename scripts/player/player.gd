extends CharacterBody2D

# Stats (will be set by ClassConfig)
@export var move_speed: float = 140.0
@export var dodge_speed: float = 280.0
@export var dodge_duration: float = 0.4
@export var dodge_cooldown: float = 0.8
@export var attack_duration: float = 0.4
@export var attack_damage: float = 20.0

var facing_direction: Vector2 = Vector2(1, 0.5).normalized()
var can_dodge: bool = true
var current_attack: Node = null
var attack_visual: Sprite2D = null

@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox
@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var mana_component: ManaComponent = $ManaComponent
@onready var card_manager: CardManager = $CardManager

func _ready() -> void:
	hitbox_shape.disabled = true

	# Generate placeholder sprite based on class
	_setup_placeholder_sprite()

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

func _setup_placeholder_sprite() -> void:
	var config: Resource = GameManager.current_class_config
	var color := Color.CORNFLOWER_BLUE
	if config:
		match config.class_id:
			&"soldier": color = Color.STEEL_BLUE
			&"rogue": color = Color.MEDIUM_SEA_GREEN
			&"mage": color = Color.MEDIUM_PURPLE
	sprite.texture = PlaceholderSprites.create_rect_texture(12, 16, color)

func apply_class_config(config: Resource) -> void:
	move_speed = config.move_speed
	dodge_speed = config.dodge_speed
	dodge_duration = config.dodge_duration
	attack_damage = config.attack_damage
	attack_duration = config.attack_duration
	health_component.max_health = config.max_health
	health_component.current_health = config.max_health
	mana_component.max_mana = config.max_mana
	mana_component.mana_per_hit_dealt = config.mana_per_hit_dealt
	mana_component.mana_per_hit_taken = config.mana_per_hit_taken
	hitbox.damage = config.attack_damage

	# Setup attack visual color based on class
	var atk_color := Color(1, 1, 0.5, 0.6)
	match config.class_id:
		&"soldier": atk_color = Color(0.8, 0.8, 1.0, 0.5)
		&"rogue": atk_color = Color(0.5, 1.0, 0.5, 0.5)
		&"mage": atk_color = Color(0.7, 0.4, 1.0, 0.5)
	attack_visual.texture = PlaceholderSprites.create_circle_texture(10, atk_color)

	# Load basic attack script
	if config.attack_script:
		var attack_node := Node.new()
		attack_node.set_script(config.attack_script)
		attack_node.name = "BasicAttack"
		add_child(attack_node)
		current_attack = attack_node

	# Initialize card deck
	if config.card_pool.size() > 0:
		card_manager.initialize_deck(config.card_pool)

func get_iso_input() -> Vector2:
	var raw: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if raw.length() < 0.1:
		return Vector2.ZERO
	var iso := Vector2(
		raw.x - raw.y,
		(raw.x + raw.y) * 0.5
	)
	return iso.normalized()

func update_facing(direction: Vector2) -> void:
	facing_direction = direction
	if direction.x < 0:
		sprite.flip_h = true
	elif direction.x > 0:
		sprite.flip_h = false

func start_attack() -> void:
	# Show attack visual
	if attack_visual:
		attack_visual.position = facing_direction * 18.0
		attack_visual.visible = true

	if current_attack and current_attack.has_method("execute"):
		current_attack.execute(self, facing_direction)
	else:
		hitbox_shape.disabled = false
		hitbox.position = facing_direction * 20.0

func end_attack() -> void:
	# Hide attack visual
	if attack_visual:
		attack_visual.visible = false

	if current_attack and current_attack.has_method("end_attack"):
		current_attack.end_attack(self)
	else:
		hitbox_shape.disabled = true
		hitbox.position = Vector2.ZERO

func set_invincible(value: bool) -> void:
	hurtbox.set_deferred("monitorable", !value)

func start_dodge_cooldown() -> void:
	var timer: SceneTreeTimer = get_tree().create_timer(dodge_cooldown)
	timer.timeout.connect(func() -> void: can_dodge = true)

func _flash_hurt() -> void:
	modulate = Color(1.5, 0.5, 0.5, 1.0)
	var timer: SceneTreeTimer = get_tree().create_timer(0.1)
	timer.timeout.connect(func() -> void: modulate = Color(1, 1, 1, 1))
