class_name EnemyData
extends Resource

## Serialized enemy tuning values.
## `base_enemy.tscn` reads this at `_ready()` and copies values into runtime stats.

## Human-readable enemy display name.
@export var enemy_name: String = "Slime"
## Internal type key used by filters and behavior setup.
@export var enemy_type: String = "slime"
## Maximum health used to initialize `HealthComponent` on spawn.
@export var max_health: float = 40.0
## Movement speed used by `BaseEnemy` AI steering.
@export var move_speed: float = 60.0
## Base melee/ranged damage before buffs, armor, and defenses.
@export var attack_damage: float = 8.0
## How far the enemy must be before it can execute an attack check.
@export var attack_range: float = 20.0
## Attack cooldown between attack checks.
@export var attack_cooldown: float = 1.5
## Max distance for target acquisition/chasing.
@export var chase_range: float = 200.0
## Shared animation frames used by `BaseEnemy` render setup.
@export var sprite_frames: SpriteFrames
## Behavior scripts attached to this enemy in this order (e.g. armor, flee, etc.).
@export var behavior_scripts: Array[Script] = []
## World-space scale multiplier for sprite and collision adjustments.
@export var visual_scale: float = 1.0
