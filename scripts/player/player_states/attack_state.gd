extends PlayerState

var attack_timer: float = 0.0

func enter() -> void:
	attack_timer = player.attack_duration
	player.velocity = Vector2.ZERO
	player.start_attack()

func physics_update(delta: float) -> void:
	attack_timer -= delta
	if attack_timer <= 0.0:
		player.end_attack()
		state_machine.transition_to("idle")

func exit() -> void:
	player.end_attack()
