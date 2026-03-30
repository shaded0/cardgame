extends "res://tests/support/test_case.gd"

const SpellEffectVisualScript = preload("res://scripts/combat/spell_effect_visual.gd")

func before_each() -> void:
	SpellEffectVisualScript._light_texture = null
	SpellEffectVisualScript._mana_gain_dot_textures.clear()

func after_each() -> void:
	SpellEffectVisualScript._light_texture = null
	SpellEffectVisualScript._mana_gain_dot_textures.clear()

func test_prewarm_common_effects_builds_shared_first_hit_assets_once() -> void:
	SpellEffectVisualScript.prewarm_common_effects()

	var first_light := SpellEffectVisualScript._light_texture
	var first_textures := SpellEffectVisualScript._mana_gain_dot_textures.duplicate()

	assert_not_null(first_light, "Prewarming spell effects should build the shared transient light texture ahead of combat.")
	assert_eq(first_textures.size(), 5, "Prewarming spell effects should cache the mana-gain dot textures used by the first attack hit.")

	SpellEffectVisualScript.prewarm_common_effects()

	assert_true(SpellEffectVisualScript._light_texture == first_light, "Repeated prewarming should reuse the existing light texture instead of rebuilding it.")
	assert_eq(SpellEffectVisualScript._mana_gain_dot_textures.size(), 5, "Repeated prewarming should keep the mana-gain cache stable instead of growing duplicate textures.")
