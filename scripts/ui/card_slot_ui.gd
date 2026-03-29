extends PanelContainer

## UI node for one card slot.
## Shows rarity-colored borders, X-cost display, exhaust badge.

@onready var card_name_label: Label = $VBoxContainer/CardName
@onready var mana_cost_label: Label = $VBoxContainer/ManaCost
@onready var key_hint_label: Label = $VBoxContainer/KeyHint

var current_card: CardData = null
var slot_index: int = 0
var _is_playable: bool = false
var _glow_time: float = 0.0
var _panel_style: StyleBoxFlat = null
var _exhaust_label: Label = null
var _rarity_indicator: Label = null
var _synergy_tween: Tween = null
var _synergy_overlay: ColorRect = null

func _ready() -> void:
	key_hint_label.text = str(slot_index + 1)
	_glow_time = slot_index * 0.7

func _process(delta: float) -> void:
	if not _is_playable or _panel_style == null:
		return

	_glow_time += delta

	# Animate border color with fiery pulse, tinted by rarity.
	var pulse := sin(_glow_time * 3.0) * 0.5 + 0.5
	var base_color: Color = _get_rarity_glow_color()
	var glow_color := Color(
		base_color.r + pulse * 0.2,
		base_color.g + pulse * 0.15,
		base_color.b + pulse * 0.1,
		0.7 + pulse * 0.3
	)
	_panel_style.border_color = glow_color

	var bw := int(2.0 + pulse * 1.5)
	_panel_style.border_width_left = bw
	_panel_style.border_width_top = bw
	_panel_style.border_width_right = bw
	_panel_style.border_width_bottom = bw

	var mana_pulse := sin(_glow_time * 2.5 + 0.5) * 0.5 + 0.5
	mana_cost_label.add_theme_color_override("font_color", Color(0.3 + mana_pulse * 0.3, 0.5, 1.0, 1.0))

func set_card_data(card: CardData) -> void:
	current_card = card
	card_name_label.text = card.card_name
	mana_cost_label.text = card.get_cost_label()
	visible = true

	# Exhaust badge
	_update_exhaust_badge()
	_update_rarity_indicator()

	# Pop-in animation with golden border flash on draw
	pivot_offset = size / 2.0
	scale = Vector2(0.8, 0.8)
	modulate.a = 0.5
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "modulate:a", 1.0, 0.15)
	# Flash border gold briefly after pop-in
	tween.chain().tween_callback(func():
		if _panel_style:
			var orig_border := _panel_style.border_color
			_panel_style.border_color = Color(1.0, 0.9, 0.5, 1.0)
			var flash_tw := create_tween()
			flash_tw.tween_method(func(c: Color): _panel_style.border_color = c,
				Color(1.0, 0.9, 0.5, 1.0), orig_border, 0.4)
	)

func clear_card() -> void:
	current_card = null
	card_name_label.text = ""
	mana_cost_label.text = ""
	modulate = Color(1, 1, 1, 1)
	_is_playable = false
	_apply_default_style()
	_update_exhaust_badge()
	_update_rarity_indicator()

func set_playable(can_play: bool) -> void:
	_is_playable = can_play
	if can_play:
		modulate = Color(1, 1, 1, 1)
		_apply_playable_style()
	else:
		modulate = Color(0.4, 0.4, 0.4, 0.7)
		_apply_default_style()

func _get_rarity_border_color() -> Color:
	if current_card == null:
		return Color(0.25, 0.28, 0.35, 0.5)
	match current_card.rarity:
		CardData.Rarity.UNCOMMON:
			return Color(0.3, 0.5, 1.0, 0.7)
		CardData.Rarity.RARE:
			return Color(1.0, 0.8, 0.2, 0.8)
		_:
			return Color(0.25, 0.28, 0.35, 0.5)

func _get_rarity_glow_color() -> Color:
	if current_card == null:
		return Color(0.8, 0.35, 0.1)
	match current_card.rarity:
		CardData.Rarity.UNCOMMON:
			return Color(0.3, 0.5, 1.0)
		CardData.Rarity.RARE:
			return Color(1.0, 0.75, 0.15)
		_:
			return Color(0.8, 0.35, 0.1)

func _apply_playable_style() -> void:
	_panel_style = StyleBoxFlat.new()
	_panel_style.bg_color = Color(0.12, 0.1, 0.16, 0.95)
	_panel_style.border_color = _get_rarity_glow_color()
	_panel_style.set_border_width_all(2)
	_panel_style.set_corner_radius_all(6)
	_panel_style.content_margin_left = 8.0
	_panel_style.content_margin_top = 6.0
	_panel_style.content_margin_right = 8.0
	_panel_style.content_margin_bottom = 6.0
	var glow: Color = _get_rarity_glow_color()
	_panel_style.shadow_color = Color(glow.r, glow.g, glow.b, 0.3)
	_panel_style.shadow_size = 6
	add_theme_stylebox_override("panel", _panel_style)

	card_name_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.9, 1.0))

func _apply_default_style() -> void:
	_panel_style = StyleBoxFlat.new()
	_panel_style.bg_color = Color(0.1, 0.12, 0.18, 0.9)
	_panel_style.border_color = _get_rarity_border_color()
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

func _update_exhaust_badge() -> void:
	if _exhaust_label:
		_exhaust_label.queue_free()
		_exhaust_label = null

	if current_card and current_card.exhaust:
		_exhaust_label = Label.new()
		_exhaust_label.text = "!"
		_exhaust_label.add_theme_font_size_override("font_size", 14)
		_exhaust_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		_exhaust_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_exhaust_label.position = Vector2(size.x - 18, 2)
		add_child(_exhaust_label)

func play_used_feedback() -> void:
	pivot_offset = size / 2.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.12, 1.12), 0.08).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate", Color(1.5, 1.3, 1.0, 1.0), 0.08)
	tween.chain().tween_property(self, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "modulate", Color(1, 1, 1, 1), 0.2)

func play_cycle_animation() -> void:
	var original_x: float = position.x
	var tween := create_tween()
	tween.tween_property(self, "position:x", original_x + 60, 0.1).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.1)
	tween.tween_callback(func(): position.x = original_x - 60)
	tween.tween_property(self, "position:x", original_x, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.12)

func play_synergy_glow(duration: float = 1.5) -> void:
	if _synergy_tween and _synergy_tween.is_valid():
		_synergy_tween.kill()

	if _synergy_overlay == null:
		_synergy_overlay = ColorRect.new()
		_synergy_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_synergy_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		_synergy_overlay.color = Color(1.0, 0.75, 0.15, 0.0)
		add_child(_synergy_overlay)

	_synergy_overlay.visible = true
	_synergy_overlay.color.a = 0.0

	_synergy_tween = create_tween()
	_synergy_tween.tween_property(_synergy_overlay, "color:a", 0.25, 0.15).set_ease(Tween.EASE_OUT)
	_synergy_tween.tween_property(_synergy_overlay, "color:a", 0.08, 0.4).set_ease(Tween.EASE_IN_OUT)
	_synergy_tween.tween_property(_synergy_overlay, "color:a", 0.2, 0.35).set_ease(Tween.EASE_IN_OUT)
	_synergy_tween.tween_property(_synergy_overlay, "color:a", 0.0, duration - 0.9)
	_synergy_tween.tween_callback(func(): _synergy_overlay.visible = false)

func _update_rarity_indicator() -> void:
	if _rarity_indicator:
		_rarity_indicator.queue_free()
		_rarity_indicator = null

	if current_card == null:
		return

	if current_card.rarity == CardData.Rarity.COMMON:
		return

	_rarity_indicator = Label.new()
	_rarity_indicator.add_theme_font_size_override("font_size", 9)
	_rarity_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rarity_indicator.position = Vector2(0, -12)
	_rarity_indicator.size = Vector2(size.x, 12)

	match current_card.rarity:
		CardData.Rarity.UNCOMMON:
			_rarity_indicator.text = "Uncommon"
			_rarity_indicator.add_theme_color_override("font_color", Color(0.3, 0.5, 1.0, 0.8))
		CardData.Rarity.RARE:
			_rarity_indicator.text = "Rare"
			_rarity_indicator.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 0.8))

	add_child(_rarity_indicator)
