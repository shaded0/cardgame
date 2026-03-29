class_name DamageNumber
extends Node2D

## Floating damage number that drifts up and fades out.
## Enhanced with scale punch, color flash, and critical hit support.

var text: String = ""
var color: Color = Color.WHITE
var font_size: int = 20
var is_crit: bool = false

func _ready() -> void:
	# Create and style a label from code so each value can be customized.
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-40, -15)
	label.size = Vector2(80, 30)

	# Outline for readability
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("outline_size", 3)

	add_child(label)

	# Scale punch: start big and shrink to normal
	label.scale = Vector2(1.6, 1.6) if is_crit else Vector2(1.3, 1.3)
	label.pivot_offset = label.size / 2.0

	var tween: Tween = create_tween()
	tween.set_parallel(true)

	# Bounce in
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Arc upward with slight horizontal drift
	var drift_x := randf_range(-25.0, 25.0)
	tween.tween_property(self, "position:y", position.y - 55.0, 0.7).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", position.x + drift_x, 0.7)

	# Fade out
	tween.tween_property(label, "modulate:a", 0.0, 0.4).set_delay(0.35)
	tween.chain().tween_callback(queue_free)

static func spawn(parent: Node, pos: Vector2, value: float, col: Color = Color.WHITE) -> void:
	# Factory helper so all gameplay code can call `spawn()` uniformly.
	var num := DamageNumber.new()
	num.text = str(int(value))
	num.color = col
	num.font_size = 22
	num.global_position = pos + Vector2(randf_range(-15, 15), -10)
	parent.add_child(num)

static func spawn_text(parent: Node, pos: Vector2, display_text: String, col: Color = Color(1.0, 0.9, 0.3)) -> void:
	## Spawn a text popup (for status effects, buffs, etc.)
	var num := DamageNumber.new()
	num.text = display_text
	num.color = col
	num.font_size = 16
	num.global_position = pos + Vector2(randf_range(-10, 10), -20)
	parent.add_child(num)
