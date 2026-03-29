class_name ClassConfig
extends Resource

@export var class_id: StringName = &"soldier"
@export var display_name: String = "Soldier"

# Combat stats
@export var max_health: float = 120.0
@export var move_speed: float = 120.0
@export var dodge_speed: float = 250.0
@export var dodge_duration: float = 0.4
@export var attack_damage: float = 20.0
@export var attack_duration: float = 0.5

# Mana stats
@export var max_mana: float = 80.0
@export var mana_per_hit_dealt: float = 10.0
@export var mana_per_hit_taken: float = 15.0

# Class-specific
@export var attack_script: Script
@export var card_pool: Array[Resource] = []
@export var sprite_frames: SpriteFrames
