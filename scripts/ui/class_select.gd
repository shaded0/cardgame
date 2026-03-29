extends Control

## Class selection screen.
## Stores the chosen class config into GameManager and then enters gameplay.

const SOLDIER_CONFIG_PATH := "res://resources/classes/soldier.tres"
const ROGUE_CONFIG_PATH := "res://resources/classes/rogue.tres"
const MAGE_CONFIG_PATH := "res://resources/classes/mage.tres"

## Button/label references from this scene.
@onready var soldier_btn: Button = $VBoxContainer/SoldierButton
@onready var rogue_btn: Button = $VBoxContainer/RogueButton
@onready var mage_btn: Button = $VBoxContainer/MageButton
@onready var description_label: Label = $VBoxContainer/Description

func _ready() -> void:
	# Wire each button using anonymous lambdas; keeps signal hookup local and compact.
	soldier_btn.pressed.connect(func(): _select_class(SOLDIER_CONFIG_PATH))
	rogue_btn.pressed.connect(func(): _select_class(ROGUE_CONFIG_PATH))
	mage_btn.pressed.connect(func(): _select_class(MAGE_CONFIG_PATH))

	# Show flavor text as the user highlights a class.
	soldier_btn.focus_entered.connect(func(): _show_description("Soldier: Melee fighter with high HP. Gains lots of mana from taking hits. Powerful close-range card abilities."))
	rogue_btn.focus_entered.connect(func(): _show_description("Rogue: Fast mid-range attacker. Low card costs for rapid play. Hit-and-run specialist."))
	mage_btn.focus_entered.connect(func(): _show_description("Mage: Long-range caster. Weak basic attack but massive card chain combos. High mana pool."))

	soldier_btn.grab_focus()

func _show_description(text: String) -> void:
	# Update one shared label instead of creating labels per button.
	description_label.text = text

func _select_class(config_path: String) -> void:
	# Loading a resource by path lets designers tune stats in external `.tres` files.
	var config := load(config_path) as ClassConfig
	if config == null:
		push_error("Failed to load class config: " + config_path)
		return

	GameManager.current_class_config = config
	# Swap scene once selection is confirmed.
	get_tree().change_scene_to_file("res://scenes/main.tscn")
