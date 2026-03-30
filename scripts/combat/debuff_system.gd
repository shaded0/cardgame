class_name DebuffSystem
extends Node

## Manages active debuffs on an enemy: vulnerable, weak, etc.
## Mirrors BuffSystem architecture on the player side.

signal debuff_applied(debuff: Debuff)
signal debuff_expired(debuff: Debuff)

var active_debuffs: Array[Debuff] = []
var enemy: CharacterBody2D

func _ready() -> void:
	enemy = get_parent() as CharacterBody2D

func _process(delta: float) -> void:
	var expired: Array[Debuff] = []
	for debuff in active_debuffs:
		if debuff.duration <= 0.0:
			continue
		debuff.remaining -= delta
		if debuff.remaining <= 0.0:
			expired.append(debuff)

	for debuff in expired:
		remove_debuff(debuff)

func add_debuff(debuff: Debuff) -> void:
	# Stack same type by refreshing duration instead of adding duplicates.
	for existing in active_debuffs:
		if existing.type == debuff.type:
			if debuff.duration <= 0.0:
				existing.duration = 0.0
				existing.remaining = 0.0
			else:
				if existing.duration > 0.0:
					existing.duration = max(existing.duration, debuff.duration)
				existing.remaining = max(existing.remaining, debuff.duration)
			debuff_applied.emit(debuff)
			_show_debuff_text(debuff)
			return

	active_debuffs.append(debuff)
	debuff_applied.emit(debuff)
	_show_debuff_text(debuff)
	_update_tint()

	# FREEZE: tell the enemy to stop all actions.
	if debuff.type == Debuff.Type.FREEZE and enemy and enemy.has_method("set_frozen"):
		enemy.set_frozen(true)

func remove_debuff(debuff: Debuff) -> void:
	if debuff in active_debuffs:
		active_debuffs.erase(debuff)
		debuff_expired.emit(debuff)
		_update_tint()

		# Unfreeze when FREEZE expires.
		if debuff.type == Debuff.Type.FREEZE and enemy and enemy.has_method("set_frozen"):
			enemy.set_frozen(false)

func get_damage_multiplier() -> float:
	## Returns 1.5 if VULNERABLE, else 1.0. Applied to incoming damage.
	for debuff in active_debuffs:
		if debuff.type == Debuff.Type.VULNERABLE:
			return 1.5
	return 1.0

func get_attack_multiplier() -> float:
	## Returns 0.75 if WEAK, else 1.0. Applied to outgoing damage.
	for debuff in active_debuffs:
		if debuff.type == Debuff.Type.WEAK:
			return 0.75
	return 1.0

func has_debuff_type(type: Debuff.Type) -> bool:
	for debuff in active_debuffs:
		if debuff.type == type:
			return true
	return false

func _show_debuff_text(debuff: Debuff) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	var parent: Node = enemy.get_parent()
	if parent == null:
		return

	var text: String
	var color: Color
	match debuff.type:
		Debuff.Type.VULNERABLE:
			text = "VULNERABLE"
			color = Color(1.0, 0.4, 0.4)
		Debuff.Type.WEAK:
			text = "WEAK"
			color = Color(0.4, 0.6, 1.0)
		Debuff.Type.FREEZE:
			text = "FROZEN"
			color = Color(0.5, 0.9, 1.0)

	# Floating status text above the enemy
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	label.global_position = enemy.global_position + Vector2(-30, -50)
	label.z_index = 10
	parent.add_child(label)

	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 30.0, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)

func _update_tint() -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	var anim: AnimatedSprite2D = enemy.get_node_or_null("AnimatedSprite")
	if anim == null:
		return

	# Blend tint based on active debuffs — FREEZE takes visual priority
	if has_debuff_type(Debuff.Type.FREEZE):
		anim.modulate = Color(0.5, 0.8, 1.5, 1.0)  # Icy blue — clearly frozen
	elif has_debuff_type(Debuff.Type.VULNERABLE) and has_debuff_type(Debuff.Type.WEAK):
		anim.modulate = Color(1.3, 0.6, 1.3, 1.0)  # Purple = both
	elif has_debuff_type(Debuff.Type.VULNERABLE):
		anim.modulate = Color(1.4, 0.7, 0.7, 1.0)  # Red tint
	elif has_debuff_type(Debuff.Type.WEAK):
		anim.modulate = Color(0.7, 0.8, 1.4, 1.0)  # Blue tint
	else:
		anim.modulate = Color(1, 1, 1, 1)  # Normal
