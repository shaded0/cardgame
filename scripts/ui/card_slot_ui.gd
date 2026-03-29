extends PanelContainer

## UI node for one card slot.
## Stores the current card resource and updates text/color based on playability.

@onready var card_name_label: Label = $VBoxContainer/CardName
@onready var mana_cost_label: Label = $VBoxContainer/ManaCost
@onready var key_hint_label: Label = $VBoxContainer/KeyHint

var current_card: Resource = null
var slot_index: int = 0

func _ready() -> void:
	# Display slot hotkey from 1..4 in-editor using zero-based index.
	key_hint_label.text = str(slot_index + 1)

func set_card_data(card: Resource) -> void:
	# Bind resource values to visible UI labels.
	current_card = card
	card_name_label.text = card.card_name
	mana_cost_label.text = str(card.mana_cost)
	visible = true

func clear_card() -> void:
	# Empty slot after card is consumed/replaced.
	current_card = null
	card_name_label.text = ""
	mana_cost_label.text = ""

func set_playable(can_play: bool) -> void:
	# Grey out cards you cannot afford to give instant feedback.
	if can_play:
		modulate = Color(1, 1, 1, 1)
	else:
		modulate = Color(0.4, 0.4, 0.4, 0.7)
