extends "res://tests/support/test_case.gd"

const Factory = preload("res://tests/support/test_factory.gd")
const ArenaFloorRendererScript = preload("res://scripts/levels/arena_floor_renderer.gd")
const ArenaFlowScript = preload("res://scripts/levels/arena_flow.gd")

var _saved_current_room: RoomData = null

class ArenaBaseDouble:
	extends ArenaBase

	func _ready() -> void:
		pass

func before_each() -> void:
	_saved_current_room = GameManager.current_room
	GameManager.current_room = null

func after_each() -> void:
	GameManager.current_room = _saved_current_room

func test_floor_renderer_uses_room_type_and_tier_when_subclass_has_not_fixed_theme() -> void:
	var owner := Node2D.new()
	root.add_child(owner)
	var renderer = ArenaFloorRendererScript.new(owner)

	var elite_room := Factory.make_room("elite", 1, [], RoomData.RoomType.ELITE)
	GameManager.current_room = elite_room
	assert_eq(renderer.resolve_theme(ArenaBase.FloorTheme.ANTECHAMBER, false), ArenaBase.FloorTheme.RITUAL, "Elite rooms should auto-select the ritual theme.")

	var boss_room := Factory.make_room("boss", 3, [], RoomData.RoomType.BOSS)
	GameManager.current_room = boss_room
	assert_eq(renderer.resolve_theme(ArenaBase.FloorTheme.ANTECHAMBER, false), ArenaBase.FloorTheme.MOLTEN_THRONE, "Boss rooms should auto-select the molten throne theme.")

	var hot_room := Factory.make_room("combat", 2, [], RoomData.RoomType.COMBAT)
	GameManager.current_room = hot_room
	assert_eq(renderer.resolve_theme(ArenaBase.FloorTheme.ANTECHAMBER, false), ArenaBase.FloorTheme.MAGMA_CORRIDOR, "Higher-tier combat rooms should use the hotter magma corridor theme.")

func test_floor_renderer_respects_subclass_theme_override_and_exposes_palette_data() -> void:
	var owner := Node2D.new()
	root.add_child(owner)
	var renderer = ArenaFloorRendererScript.new(owner)

	GameManager.current_room = Factory.make_room("elite", 1, [], RoomData.RoomType.ELITE)
	var resolved_theme := renderer.resolve_theme(ArenaBase.FloorTheme.MAGMA_CORRIDOR, true)
	assert_eq(resolved_theme, ArenaBase.FloorTheme.MAGMA_CORRIDOR, "Subclass-selected themes should win over automatic room-based theme selection.")

	var palette := renderer.get_palette(ArenaBase.FloorTheme.RITUAL)
	assert_eq(palette["accent"], Color(0.7, 0.3, 0.9), "Palette lookup should stay stable so downstream visuals keep the intended color identity.")
	assert_eq(palette["light_color"], Color(0.9, 0.75, 1.0), "Palette lookup should expose lighting data for the extracted visuals helper.")

func test_flow_configures_enemy_count_from_current_room_and_preserves_default_without_room() -> void:
	var owner := Node2D.new()
	root.add_child(owner)
	var flow = ArenaFlowScript.new(owner)

	GameManager.current_room = Factory.make_room("combat", 1, [], RoomData.RoomType.COMBAT)
	GameManager.current_room.enemy_count = 7
	assert_eq(flow.configure_from_current_room(4), 7, "Flow helper should adopt the room's configured enemy count.")

	GameManager.current_room = null
	assert_eq(flow.configure_from_current_room(4), 4, "Flow helper should preserve the caller's default when no room is active.")

func test_flow_room_clear_waits_for_wave_to_spawn_and_all_enemies_to_die() -> void:
	var owner := Node2D.new()
	root.add_child(owner)
	var flow = ArenaFlowScript.new(owner)

	assert_false(flow.room_cleared(false, false), "Rooms should not clear before the opening wave has actually spawned.")

	var enemy := Node2D.new()
	enemy.add_to_group("enemies")
	root.add_child(enemy)
	assert_false(flow.room_cleared(true, false), "Any surviving enemy should keep the room uncleared.")

	enemy.remove_from_group("enemies")
	enemy.queue_free()
	assert_true(flow.room_cleared(true, false), "Once the wave has spawned and enemies are gone, the room should clear.")
	assert_true(flow.room_cleared(true, true), "Once cleared, the flow helper should keep the room in the cleared state.")

func test_arena_base_configures_room_theme_enemy_count_and_spawn_helpers() -> void:
	var arena := _make_arena_under_test()
	var room := Factory.make_room("combat", 2, [], RoomData.RoomType.COMBAT)
	room.enemy_count = 6
	GameManager.current_room = room

	arena._pick_room_palette()
	arena._configure_from_current_room()

	assert_eq(arena.floor_theme, ArenaBase.FloorTheme.MAGMA_CORRIDOR, "ArenaBase should delegate room-based theme selection through the extracted floor renderer.")
	assert_eq(arena.enemies_to_spawn, 6, "ArenaBase should still pull the room's enemy count through the extracted flow helper.")

	var spawn := arena._get_spawn_offset(150.0, 200.0)
	var approx_radius := absf(spawn.x) + absf(spawn.y) * 2.0
	assert_true(approx_radius >= 150.0 and approx_radius <= 200.0, "Spawn offsets should stay within the requested isometric radius band.")

func test_arena_base_adds_decorations_and_grass_to_entity_layer() -> void:
	var arena := _make_arena_under_test()
	arena._palette = ArenaFloorRendererScript.PALETTES[ArenaBase.FloorTheme.ANTECHAMBER]

	arena._add_decoration(ArenaDecoration.DecorType.BRAZIER, Vector2(32, 16))
	arena._add_grass_cluster(Vector2.ZERO, 2, 0.0)

	assert_eq(arena.entity_layer.get_child_count(), 3, "ArenaBase should keep routing decoration and grass creation through the entity layer after the coordinator split.")
	assert_true(arena.entity_layer.get_child(0) is ArenaDecoration, "Decoration helper should still instantiate ArenaDecoration nodes.")
	assert_true(arena.entity_layer.get_child(1) is GrassPatch and arena.entity_layer.get_child(2) is GrassPatch, "Grass cluster helper should still instantiate the requested number of grass patches.")

func _make_arena_under_test() -> ArenaBase:
	var arena := ArenaBaseDouble.new()
	arena.name = "ArenaUnderTest"
	var entity_layer := Node2D.new()
	entity_layer.name = "EntityLayer"
	arena.add_child(entity_layer)
	root.add_child(arena)
	arena._floor_renderer = ArenaFloorRendererScript.new(arena)
	arena._flow = ArenaFlowScript.new(arena)
	return arena
