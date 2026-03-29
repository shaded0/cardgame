class_name PlayerState
extends Node

## Base class for player states.
## Concrete states override the three lifecycle hooks.

var state_machine: PlayerStateMachine
var player: CharacterBody2D

func enter() -> void:
	pass

func exit() -> void:
	pass

func handle_input(_event: InputEvent) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass
