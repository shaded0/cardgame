class_name CardData
extends Resource

enum CardClass { NEUTRAL, SOLDIER, ROGUE, MAGE }

@export var card_name: String = ""
@export var card_class: CardClass = CardClass.NEUTRAL
@export_multiline var description: String = ""
@export var mana_cost: int = 10
@export var cooldown: float = 0.0
@export var card_icon: Texture2D
@export var effects: Array[Resource] = []  # Array of CardEffect
@export var chain_card: Resource  # CardData for mage chains
@export var generates_mana: int = 0
