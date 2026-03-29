class_name SpriteAnimator
extends RefCounted

## Thin facade that preserves the existing public API while delegating
## frame construction to focused generator modules.

const HumanoidFrames = preload("res://scripts/managers/sprite_animator_humanoid.gd")
const EnemyCoreFrames = preload("res://scripts/managers/sprite_animator_enemy_core.gd")
const EnemyVariantFrames = preload("res://scripts/managers/sprite_animator_enemy_variants.gd")

static func create_humanoid_frames(body_color: Color, detail_color: Color, weapon: String = "sword") -> SpriteFrames:
	return HumanoidFrames.create_humanoid_frames(body_color, detail_color, weapon)

static func create_slime_frames(body_color: Color) -> SpriteFrames:
	return EnemyCoreFrames.create_slime_frames(body_color)

static func create_skeleton_frames() -> SpriteFrames:
	return EnemyCoreFrames.create_skeleton_frames()

static func create_imp_frames() -> SpriteFrames:
	return EnemyCoreFrames.create_imp_frames()

static func create_wraith_frames() -> SpriteFrames:
	return EnemyCoreFrames.create_wraith_frames()

static func create_golem_frames() -> SpriteFrames:
	return EnemyCoreFrames.create_golem_frames()

static func create_rat_frames() -> SpriteFrames:
	return EnemyVariantFrames.create_rat_frames()

static func create_shaman_frames() -> SpriteFrames:
	return EnemyVariantFrames.create_shaman_frames()

static func create_beetle_frames() -> SpriteFrames:
	return EnemyVariantFrames.create_beetle_frames()

static func create_banshee_frames() -> SpriteFrames:
	return EnemyVariantFrames.create_banshee_frames()

static func create_colossus_frames() -> SpriteFrames:
	return EnemyVariantFrames.create_colossus_frames()
