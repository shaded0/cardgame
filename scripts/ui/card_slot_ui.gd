extends PanelContainer

@onready var card_name_label: Label = $VBoxContainer/CardName
@onready var mana_cost_label: Label = $VBoxContainer/ManaCost
@onready var key_hint_label: Label = $VBoxContainer/KeyHint

var current_card: Resource = null
var slot_index: int = 0

func _ready() -> void:
	key_hint_label.text = str(slot_index + 1)

func set_card_data(card: Resource) -> void:
	current_card = card
	card_name_label.text = card.card_name
	mana_cost_label.text = str(card.mana_cost)
	visible = true

func clear_card() -> void:
	current_card = null
	card_name_label.text = ""
	mana_cost_label.text = ""

func set_playable(can_play: bool) -> void:
	if can_play:
		modulate = Color(1, 1, 1, 1)
	else:
		modulate = Color(0.4, 0.4, 0.4, 0.7)
