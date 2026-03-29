class_name CardEffect
extends Resource

## One declarative card effect.
## Card resolver switches on `type` and applies behavior + visuals.

enum EffectType { DAMAGE, HEAL, BUFF, AOE, PROJECTILE, SUMMON, MANA_GEN, SHIELD, DEBUFF, MULTI_HIT }
enum TargetMode { NEAREST_ENEMY, CURSOR, SELF, ALL_ENEMIES, AREA_AT_CURSOR }
enum BuffType { DAMAGE_UP, SPEED_UP, DEFENSE_UP, EMPOWER_NEXT, DODGE_BOOST }
enum DebuffType { VULNERABLE, WEAK, FREEZE }

@export var type: EffectType = EffectType.DAMAGE
@export var value: float = 10.0
@export var radius: float = 0.0
@export var duration: float = 0.0
@export var effect_scene: PackedScene
@export var target_mode: TargetMode = TargetMode.NEAREST_ENEMY
@export var buff_type: BuffType = BuffType.DAMAGE_UP
@export var debuff_type: DebuffType = DebuffType.VULNERABLE
@export var stacks: int = 1
@export var hit_count: int = 1  ## For MULTI_HIT: number of damage instances
