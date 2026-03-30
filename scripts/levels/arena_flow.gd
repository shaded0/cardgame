extends RefCounted

const CARD_REWARD_SCREEN_SCENE := preload("res://scenes/ui/card_reward_screen.tscn")

var _owner: Node2D

func _init(owner: Node2D) -> void:
	_owner = owner

func configure_from_current_room(current_count: int) -> int:
	if GameManager.current_room:
		return GameManager.current_room.enemy_count
	return current_count

func restore_player_health() -> void:
	if GameManager.player_health_carry <= 0.0:
		return
	var player: PlayerController = GameManager.get_player()
	if player == null or not player.has_node("HealthComponent"):
		return
	var health: HealthComponent = player.get_node("HealthComponent")
	health.set_current_health(GameManager.player_health_carry)

func spawn_enemies(enemies_to_spawn: int) -> bool:
	for i in range(enemies_to_spawn):
		var enemy: Node = _owner.call("_spawn_enemy_in_radius", 300.0, 650.0)
		if enemy and enemy.has_method("set_aggro_delay"):
			enemy.set_aggro_delay(i * 0.8)
	return true

func room_cleared(enemies_spawned: bool, room_is_cleared: bool) -> bool:
	if enemies_spawned and not room_is_cleared and GameManager.get_enemies().is_empty():
		return true
	return room_is_cleared

func handle_room_cleared() -> void:
	_owner.emit_signal("room_cleared")

	var player: PlayerController = GameManager.get_player()
	if player and player.has_node("HealthComponent"):
		var health: HealthComponent = player.get_node("HealthComponent")
		GameManager.player_health_carry = health.current_health

	if GameManager.current_room:
		GameManager.complete_room(GameManager.current_room.room_id)

	var is_boss := GameManager.current_room and GameManager.current_room.room_type == RoomData.RoomType.BOSS
	var label := _build_clear_label(is_boss)
	var ui_layer: CanvasLayer = _owner.get_node_or_null("UILayer")
	if ui_layer:
		ui_layer.add_child(label)
	else:
		_owner.add_child(label)

	ScreenFX.shake(_owner, 10.0, 0.2)
	var anim := _owner.create_tween()
	anim.set_parallel(true)
	anim.tween_property(label, "modulate:a", 1.0, 0.15)
	anim.tween_property(label, "scale", Vector2(1.0, 1.0), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	anim.chain()
	anim.tween_property(label, "scale", Vector2(1.05, 1.05), 0.5).set_ease(Tween.EASE_IN_OUT)
	anim.tween_property(label, "scale", Vector2(1.0, 1.0), 0.5).set_ease(Tween.EASE_IN_OUT)

	if is_boss:
		await _owner.get_tree().create_timer(3.0).timeout
		GameManager.run_active = false
		GameManager.go_to_class_select()
		return

	await _owner.get_tree().create_timer(1.5).timeout
	_show_card_rewards()

func _show_card_rewards() -> void:
	var reward_screen: CardRewardScreen = CARD_REWARD_SCREEN_SCENE.instantiate() as CardRewardScreen
	if reward_screen == null:
		return

	var is_elite: bool = GameManager.current_room and GameManager.current_room.room_type == RoomData.RoomType.ELITE
	var class_id: StringName = &"soldier"
	if GameManager.current_class_config:
		class_id = GameManager.current_class_config.class_id

	var ui_layer: CanvasLayer = _owner.get_node_or_null("UILayer")
	if ui_layer:
		ui_layer.add_child(reward_screen)
	else:
		_owner.add_child(reward_screen)

	reward_screen.setup(class_id, is_elite)
	reward_screen.card_chosen.connect(func(card: CardData) -> void:
		GameManager.add_card_to_deck(card)
		GameManager.go_to_map()
	)
	reward_screen.rewards_skipped.connect(func() -> void:
		GameManager.go_to_map()
	)

func _build_clear_label(is_boss: bool) -> Label:
	var label := Label.new()
	label.text = "VICTORY!" if is_boss else "ROOM CLEARED!"
	label.add_theme_font_size_override("font_size", 52)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.6, 0.2, 0.0, 0.9))
	label.add_theme_constant_override("outline_size", 4)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.position = Vector2(-250, -40)
	label.size = Vector2(500, 80)
	label.modulate.a = 0.0
	label.pivot_offset = Vector2(250, 40)
	label.scale = Vector2(2.0, 2.0)
	return label
