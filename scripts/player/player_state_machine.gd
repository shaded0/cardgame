class_name PlayerStateMachine
extends Node

## Lightweight state machine for the player.
## Children nodes are states (attack/move/idle/dodge), each implementing `enter`, `exit`, and `physics_update`.

const INPUT_BUFFER_DURATION: float = 0.18

var current_state: Node
var states: Dictionary = {}
var _attack_buffer_remaining: float = 0.0
var _dodge_buffer_remaining: float = 0.0

func _ready() -> void:
	# Collect child state nodes by lowercase name to allow transition by string.
	for child in get_children():
		states[child.name.to_lower()] = child
		child.state_machine = self
		child.player = get_parent() as PlayerController
	current_state = states.get("idle")
	if current_state:
		current_state.enter()

func _physics_process(delta: float) -> void:
	# Keep all movement + animation updates in physics step for deterministic movement.
	if Input.is_action_just_pressed("basic_attack"):
		buffer_attack_input()
	if Input.is_action_just_pressed("dodge"):
		buffer_dodge_input()

	_attack_buffer_remaining = maxf(_attack_buffer_remaining - delta, 0.0)
	_dodge_buffer_remaining = maxf(_dodge_buffer_remaining - delta, 0.0)
	if current_state:
		current_state.physics_update(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("basic_attack"):
		buffer_attack_input()
	elif event.is_action_pressed("dodge"):
		buffer_dodge_input()
	# Let the active state decide whether this input means transition.
	if current_state:
		current_state.handle_input(event)

func transition_to(state_name: String) -> void:
	# Centralize state changes and guarantee exit->enter lifecycle.
	if not states.has(state_name):
		push_warning("State '%s' not found" % state_name)
		return
	var previous_state_name := "none" if current_state == null else current_state.name.to_lower()
	if current_state:
		current_state.exit()
	current_state = states[state_name]
	GameManager.log_attack("state_machine", "transition", {"from": previous_state_name, "to": state_name})
	current_state.enter()

func is_in_state(state_name: String) -> bool:
	return current_state == states.get(state_name)

func recover_to_neutral() -> void:
	var player_node: PlayerController = get_parent() as PlayerController
	if player_node == null:
		return
	GameManager.log_attack("state_machine", "recover_to_neutral", {"attack_buffer": has_attack_buffer(), "dodge_buffer": has_dodge_buffer()})
	if consume_attack_buffer():
		transition_to("attack")
	elif player_node.can_dodge and consume_dodge_buffer():
		transition_to("dodge")
	elif player_node.get_iso_input() != Vector2.ZERO:
		transition_to("move")
	else:
		transition_to("idle")

func buffer_attack_input() -> void:
	_attack_buffer_remaining = INPUT_BUFFER_DURATION
	GameManager.log_attack("state_machine", "buffer_attack", {"state": current_state.name.to_lower() if current_state else "none"})

func buffer_dodge_input() -> void:
	_dodge_buffer_remaining = INPUT_BUFFER_DURATION
	GameManager.log_attack("state_machine", "buffer_dodge", {"state": current_state.name.to_lower() if current_state else "none"})

func consume_attack_buffer() -> bool:
	if _attack_buffer_remaining <= 0.0:
		return false
	_attack_buffer_remaining = 0.0
	return true

func consume_dodge_buffer() -> bool:
	if _dodge_buffer_remaining <= 0.0:
		return false
	_dodge_buffer_remaining = 0.0
	return true

func has_attack_buffer() -> bool:
	return _attack_buffer_remaining > 0.0

func has_dodge_buffer() -> bool:
	return _dodge_buffer_remaining > 0.0
