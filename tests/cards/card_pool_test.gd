extends "res://tests/support/test_case.gd"

const Factory = preload("res://tests/support/test_factory.gd")
const CardPoolScript = preload("res://scripts/cards/card_pool.gd")

class DeterministicCardPool:
	extends CardPool

	func _init() -> void:
		pass

	func _weighted_pick(cards: Array[CardData], _is_elite: bool) -> CardData:
		return cards[0]

var _saved_run_deck: Array[CardData] = []

func before_each() -> void:
	_saved_run_deck = GameManager.run_deck.duplicate()

func after_each() -> void:
	GameManager.run_deck = _saved_run_deck.duplicate()

func test_reward_pool_treats_upgraded_cards_as_already_owned() -> void:
	var base_card := Factory.make_card("Strike")
	var upgraded_card := Factory.make_card("Strike+")
	upgraded_card.is_upgraded = true
	var fresh_card := Factory.make_card("Brand New")

	GameManager.run_deck = [upgraded_card]

	var pool: DeterministicCardPool = DeterministicCardPool.new()
	pool.all_cards = [base_card, fresh_card]

	var rewards := pool.get_reward_options(&"soldier", 1, false)

	assert_eq(rewards.size(), 1, "Reward generation should still return one option when a deterministic pool is configured.")
	assert_eq(rewards[0], fresh_card, "Owning an upgraded card should make the base card count as already owned so truly fresh cards are preferred first.")

func test_canonical_card_name_strips_upgrade_suffixes() -> void:
	var pool: CardPool = CardPoolScript.new()

	assert_eq(pool._canonical_card_name("Fireball+"), "Fireball", "Single-upgrade suffixes should normalize to the base card archetype.")
	assert_eq(pool._canonical_card_name("Fireball++"), "Fireball", "Repeated upgrade suffixes should still normalize to the same base card archetype.")
