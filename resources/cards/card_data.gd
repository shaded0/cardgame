class_name CardData
extends Resource

## Data shape for playable cards.
## `effects` are resolved by `CardEffectResolver`.

enum CardClass { NEUTRAL, SOLDIER, ROGUE, MAGE }
enum Rarity { COMMON, UNCOMMON, RARE }

@export var card_name: String = ""
@export var card_class: CardClass = CardClass.NEUTRAL
@export var rarity: Rarity = Rarity.COMMON
@export_multiline var description: String = ""
@export var mana_cost: int = 10
@export var cooldown: float = 0.0
@export var card_icon: Texture2D
@export var effects: Array[CardEffect] = []
@export var chain_card: CardData
@export var generates_mana: int = 0
@export var pauses_game: bool = false
@export var exhaust: bool = false        ## Removed from deck after play (one-time use)
@export var is_x_cost: bool = false      ## Spend ALL mana; effect.value = per-mana multiplier
@export var upgraded_version: CardData   ## Points to the "+" upgraded version
@export var is_upgraded: bool = false    ## True on upgraded card variants

func get_cost_label() -> String:
	return "X" if is_x_cost else str(mana_cost)
