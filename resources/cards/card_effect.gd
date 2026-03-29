class_name CardEffect
extends Resource

## One declarative card effect.
## Card resolver switches on `type` and applies behavior + visuals.

enum EffectType { DAMAGE, HEAL, BUFF, AOE, PROJECTILE, SUMMON, MANA_GEN, SHIELD, DEBUFF, MULTI_HIT }
enum TargetMode { NEAREST_ENEMY, CURSOR, SELF, ALL_ENEMIES, AREA_AT_CURSOR }
enum BuffType { DAMAGE_UP, SPEED_UP, DEFENSE_UP, EMPOWER_NEXT, DODGE_BOOST }
enum DebuffType { VULNERABLE, WEAK, FREEZE }

## Effect category resolved by `CardEffectResolver`.
@export var type: EffectType = EffectType.DAMAGE
## Effect magnitude (damage/heal/value/stack multiplier depending on type).
@export var value: float = 10.0
## Optional area radius for AOE and cursor-area effects.
@export var radius: float = 0.0
## Duration in seconds for time-bound buffs/debuffs/statuses.
@export var duration: float = 0.0
## Optional scene for cast VFX (projectile splash, summon visuals, etc.).
@export var effect_scene: PackedScene
## Targeting mode used when applying this effect.
@export var target_mode: TargetMode = TargetMode.NEAREST_ENEMY
## Buff subtype for `BUFF` type effects.
@export var buff_type: BuffType = BuffType.DAMAGE_UP
## Debuff subtype for `DEBUFF` type effects.
@export var debuff_type: DebuffType = DebuffType.VULNERABLE
## Stack count for buffs/debuffs and multi-instance effects.
@export var stacks: int = 1
## For MULTI_HIT, how many repeated damage events to apply.
@export var hit_count: int = 1  ## For MULTI_HIT: number of damage instances
