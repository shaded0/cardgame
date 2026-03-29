class_name RoomData
extends Resource

## Serialized room metadata used to build and run the map graph.
## Map nodes reference these resources at runtime and drive both UI and scene flow.
enum RoomType { COMBAT, ELITE, REST, BOSS }

## Stable identifier used by completion logic and map node lookups.
@export var room_id: String = ""
## Human-readable room title shown in UI.
@export var display_name: String = ""
## Short lore/description displayed in cards, tooltips, and room previews.
@export_multiline var description: String = ""
## Controls which kind of encounter scene gets loaded and how progression treats this room.
@export var room_type: RoomType = RoomType.COMBAT
## Packed scene path used when the run enters this room.
@export var arena_scene_path: String = ""
## Baseline enemy count used as a difficulty hint for combat rooms.
@export var enemy_count: int = 4
## Vertical position on the map (0 = bottom/start).
@export var tier: int = 0
## Room ids this room can transition to.
@export var connections: Array[String] = []
## Pool of possible enemy types to spawn (randomly selected when entering combat).
@export var enemy_types: Array[EnemyData] = []
