class_name CardData
extends Resource

## Data shape for playable cards.
## `effects` are resolved by `CardEffectResolver`.

enum CardClass { NEUTRAL, SOLDIER, ROGUE, MAGE }
enum Rarity { COMMON, UNCOMMON, RARE }

## Internal name shown in deck/build menus and test diagnostics.
@export var card_name: String = ""
## Determines which class can freely use this card.
@export var card_class: CardClass = CardClass.NEUTRAL
## Rarity gate for collection/power scaling and pool curation.
@export var rarity: Rarity = Rarity.COMMON
## Multi-line rules text shown in UI tooltips.
@export_multiline var description: String = ""
## Base mana cost before X-cost and class restrictions apply.
@export var mana_cost: int = 10
## Cooldown between casts; `0` means immediately reusable once conditions pass.
@export var cooldown: float = 0.0
## UI icon and optional card art lookup.
@export var card_icon: Texture2D
## Ordered effect list fed through `CardEffectResolver`.
@export var effects: Array[CardEffect] = []
## Optional follow-up card granted after this one is played.
@export var chain_card: CardData
## Extra mana this card grants when resolved.
@export var generates_mana: int = 0
## If true, entering card resolution pauses in-world timers/flow.
@export var pauses_game: bool = false
@export var exhaust: bool = false        ## Removed from deck after play (one-time use)
@export var is_x_cost: bool = false      ## Spend ALL mana; effect.value = per-mana multiplier
## If true, points to a direct upgrade transform used by upgrade flow.
@export var upgraded_version: CardData   ## Points to the "+" upgraded version
@export var is_upgraded: bool = false    ## True on upgraded card variants

func get_cost_label() -> String:
	return "X" if is_x_cost else str(mana_cost)
