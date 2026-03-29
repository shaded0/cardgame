extends PanelContainer

## UI node for one card slot.
## Stores the current card resource and updates text/color based on playability.
## Enhanced with fiery glow border when cards are playable.

@onready var card_name_label: Label = $VBoxContainer/CardName
@onready var mana_cost_label: Label = $VBoxContainer/ManaCost
@onready var key_hint_label: Label = $VBoxContainer/KeyHint

var current_card: CardData = null
var slot_index: int = 0
var _is_playable: bool = false
var _glow_time: float = 0.0
var _panel_style: StyleBoxFlat = null

func _ready() -> void:
	# Display slot hotkey from 1..4 in-editor using zero-based index.
	key_hint_label.text = str(slot_index + 1)
	# Stagger glow animation per slot so they don't all pulse in sync.
	_glow_time = slot_index * 0.7

func _process(delta: float) -> void:
	if not _is_playable or _panel_style == null:
		return

	_glow_time += delta

	# Animate border color with fiery pulse
	var pulse := sin(_glow_time * 3.0) * 0.5 + 0.5
	var glow_color := Color(
		0.8 + pulse * 0.2,
		0.35 + pulse * 0.25,
		0.1 + pulse * 0.1,
		0.7 + pulse * 0.3
	)
	_panel_style.border_color = glow_color

	# Subtle border width pulse
	var bw := int(2.0 + pulse * 1.5)
	_panel_style.border_width_left = bw
	_panel_style.border_width_top = bw
	_panel_style.border_width_right = bw
	_panel_style.border_width_bottom = bw

	# Animate mana cost label color
	var mana_pulse := sin(_glow_time * 2.5 + 0.5) * 0.5 + 0.5
	mana_cost_label.add_theme_color_override("font_color", Color(0.3 + mana_pulse * 0.3, 0.5, 1.0, 1.0))

func set_card_data(card: CardData) -> void:
	# Bind resource values to visible UI labels.
	current_card = card
	card_name_label.text = card.card_name
	mana_cost_label.text = "X" if card.is_x_cost else str(card.mana_cost)
	visible = true

	# Pop-in animation when a new card arrives
	scale = Vector2(0.8, 0.8)
	modulate.a = 0.5
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "modulate:a", 1.0, 0.15)

func clear_card() -> void:
	# Empty slot after card is consumed/replaced.
	current_card = null
	card_name_label.text = ""
	mana_cost_label.text = ""
	modulate = Color(1, 1, 1, 1)
	_is_playable = false
	_apply_default_style()

func set_playable(can_play: bool) -> void:
	_is_playable = can_play
	if can_play:
		modulate = Color(1, 1, 1, 1)
		_apply_playable_style()
	else:
		modulate = Color(0.4, 0.4, 0.4, 0.7)
		_apply_default_style()

func _apply_playable_style() -> void:
	_panel_style = StyleBoxFlat.new()
	_panel_style.bg_color = Color(0.12, 0.1, 0.16, 0.95)
	_panel_style.border_color = Color(1.0, 0.5, 0.2, 0.8)
	_panel_style.set_border_width_all(2)
	_panel_style.set_corner_radius_all(6)
	_panel_style.content_margin_left = 8.0
	_panel_style.content_margin_top = 6.0
	_panel_style.content_margin_right = 8.0
	_panel_style.content_margin_bottom = 6.0
	# Shadow glow beneath the card
	_panel_style.shadow_color = Color(1.0, 0.4, 0.1, 0.3)
	_panel_style.shadow_size = 6
	add_theme_stylebox_override("panel", _panel_style)

	card_name_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.9, 1.0))

func _apply_default_style() -> void:
	_panel_style = StyleBoxFlat.new()
	_panel_style.bg_color = Color(0.1, 0.12, 0.18, 0.9)
	_panel_style.border_color = Color(0.25, 0.28, 0.35, 0.5)
	_panel_style.set_border_width_all(2)
	_panel_style.set_corner_radius_all(6)
	_panel_style.content_margin_left = 8.0
	_panel_style.content_margin_top = 6.0
	_panel_style.content_margin_right = 8.0
	_panel_style.content_margin_bottom = 6.0
	_panel_style.shadow_color = Color(0, 0, 0, 0)
	_panel_style.shadow_size = 0
	add_theme_stylebox_override("panel", _panel_style)

	card_name_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 1.0))
