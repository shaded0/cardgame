class_name Hitbox
extends Area2D

## Hitbox emits `hit_landed` when touching a Hurtbox and notifies the target.
## Supports one-shot mode for projectiles and hit-stop for impactful feel.

signal hit_landed(hurtbox: Area2D)

@export var damage: float = 10.0
## When true, this hitbox disables itself after the first hit (projectiles).
@export var one_shot: bool = false
## Tracks which hurtboxes have been hit to prevent multi-hit in a single swing.
var _hit_targets: Array[Area2D] = []
static var _hit_stop_depth: int = 0
static var _hit_stop_restore_scale: float = 1.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		# Prevent hitting the same target twice in one attack window.
		if area in _hit_targets:
			return
		_hit_targets.append(area)

		hit_landed.emit(area)
		area.receive_hit(self)

		if one_shot:
			_disable()

func reset_targets() -> void:
	## Call between attack swings to allow re-hitting the same enemies.
	_hit_targets.clear()

func _disable() -> void:
	## Safely disable after one-shot hit.
	var col: CollisionShape2D = get_node_or_null("CollisionShape2D")
	if col:
		col.set_deferred("disabled", true)
	set_deferred("monitoring", false)

func _do_hit_stop() -> void:
	## Brief engine freeze (hitstop) for weighty combat feel.
	## Only applies when inside the scene tree.
	if not is_inside_tree():
		return
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	# Keep nested hit-stops from restoring back to the slowed value.
	if _hit_stop_depth == 0:
		_hit_stop_restore_scale = Engine.time_scale
		Engine.time_scale = minf(Engine.time_scale, 0.05)
	_hit_stop_depth += 1

	await tree.create_timer(0.04, true, false, true).timeout

	_hit_stop_depth = maxi(_hit_stop_depth - 1, 0)
	if _hit_stop_depth == 0:
		Engine.time_scale = _hit_stop_restore_scale
