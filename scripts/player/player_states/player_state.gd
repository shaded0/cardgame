class_name PlayerState
extends Node

## Base class for player states.
## Concrete states override the three lifecycle hooks.

## Set by the state machine when entering this state.
var state_machine: PlayerStateMachine
## Back-reference to owning player for intent + transitions.
var player = null

## Called when this state becomes active.
func enter() -> void:
	pass

## Called before state is replaced by another state.
func exit() -> void:
	pass

## Handle raw input events while active.
func handle_input(_event: InputEvent) -> void:
	pass

## Perform per-frame physics/state transitions when this state is active.
func physics_update(_delta: float) -> void:
	pass
