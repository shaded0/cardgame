class_name DamageNumber
extends Node2D

## Floating damage number that drifts up and fades out.

var text: String = ""
var color: Color = Color.WHITE
var font_size: int = 20

func _ready() -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-30, -10)
	add_child(label)

	# Float up and fade
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 50.0, 0.6).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.2)
	tween.chain().tween_callback(queue_free)

static func spawn(parent: Node, pos: Vector2, value: float, col: Color = Color.WHITE) -> void:
	var num := DamageNumber.new()
	num.text = str(int(value))
	num.color = col
	num.global_position = pos + Vector2(randf_range(-15, 15), -10)
	parent.add_child(num)
