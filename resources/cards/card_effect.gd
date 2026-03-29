class_name CardEffect
extends Resource

enum EffectType { DAMAGE, HEAL, BUFF, AOE, PROJECTILE, SUMMON, MANA_GEN, SHIELD }
enum TargetMode { NEAREST_ENEMY, CURSOR, SELF, ALL_ENEMIES, AREA_AT_CURSOR }

@export var type: EffectType = EffectType.DAMAGE
@export var value: float = 10.0
@export var radius: float = 0.0
@export var duration: float = 0.0
@export var effect_scene: PackedScene
@export var target_mode: TargetMode = TargetMode.NEAREST_ENEMY
