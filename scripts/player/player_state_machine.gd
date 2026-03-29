class_name PlayerStateMachine
extends Node

## Lightweight state machine for the player.
## Children nodes are states (attack/move/idle/dodge), each implementing `enter`, `exit`, and `physics_update`.

var current_state: Node
var states: Dictionary = {}

func _ready() -> void:
	# Collect child state nodes by lowercase name to allow transition by string.
	for child in get_children():
		states[child.name.to_lower()] = child
		child.state_machine = self
		child.player = get_parent()
	current_state = states.get("idle")
	if current_state:
		current_state.enter()

func _physics_process(delta: float) -> void:
	# Keep all movement + animation updates in physics step for deterministic movement.
	if current_state:
		current_state.physics_update(delta)

func _unhandled_input(event: InputEvent) -> void:
	# Let the active state decide whether this input means transition.
	if current_state:
		current_state.handle_input(event)

func transition_to(state_name: String) -> void:
	# Centralize state changes and guarantee exit->enter lifecycle.
	if not states.has(state_name):
		push_warning("State '%s' not found" % state_name)
		return
	if current_state:
		current_state.exit()
	current_state = states[state_name]
	current_state.enter()
