class_name RoomData
extends Resource

enum RoomType { COMBAT, ELITE, REST, BOSS }

@export var room_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var room_type: RoomType = RoomType.COMBAT
@export var arena_scene_path: String = ""
@export var enemy_count: int = 4
@export var tier: int = 0  ## Vertical position on the map (0 = bottom/start)
@export var connections: Array[String] = []  ## room_ids this connects to
