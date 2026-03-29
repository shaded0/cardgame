class_name CardPool
extends RefCounted

## Loads all card .tres files and provides weighted-random selection for rewards.
## Instantiated on demand by the card reward screen.

var all_cards: Array[CardData] = []

func _init() -> void:
	_load_all_cards()

func _load_all_cards() -> void:
	all_cards.clear()
	var dirs: Array[String] = [
		"res://resources/cards/neutral/",
		"res://resources/cards/soldier/",
		"res://resources/cards/rogue/",
		"res://resources/cards/mage/",
	]
	for dir_path in dirs:
		var dir := DirAccess.open(dir_path)
		if dir == null:
			continue
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var full_path: String = dir_path + file_name
				var card: CardData = load(full_path) as CardData
				if card and not card.is_upgraded:
					all_cards.append(card)
			file_name = dir.get_next()

func get_reward_options(class_id: StringName, count: int = 3, is_elite: bool = false) -> Array[CardData]:
	## Returns `count` random cards, weighted by rarity, for the given class.
	## Elite rooms skew toward higher rarity.
	## Prefer new cards first, but fall back to owned cards so reward screens still offer real choices late in a run.
	var fresh_cards: Array[CardData] = []
	var fallback_cards: Array[CardData] = []
	var current_deck: Array[CardData] = GameManager.run_deck

	for card in all_cards:
		if not _matches_class(card, class_id):
			continue

		if _deck_contains_card_name(current_deck, card.card_name):
			fallback_cards.append(card)
		else:
			fresh_cards.append(card)

	var results: Array[CardData] = _pick_unique_cards(fresh_cards, count, is_elite)
	if results.size() < count:
		var already_picked: Array[String] = []
		for card in results:
			already_picked.append(card.card_name)

		var duplicate_fallback: Array[CardData] = []
		for card in fallback_cards:
			if card.card_name in already_picked:
				continue
			duplicate_fallback.append(card)

		results.append_array(_pick_unique_cards(duplicate_fallback, count - results.size(), is_elite))

	return results

func _pick_unique_cards(source: Array[CardData], count: int, is_elite: bool) -> Array[CardData]:
	var pool: Array[CardData] = source.duplicate()
	var results: Array[CardData] = []
	for _i in range(count):
		if pool.is_empty():
			break
		var pick: CardData = _weighted_pick(pool, is_elite)
		results.append(pick)
		pool.erase(pick)
	return results

func _matches_class(card: CardData, class_id: StringName) -> bool:
	match class_id:
		&"soldier":
			return card.card_class == CardData.CardClass.SOLDIER or card.card_class == CardData.CardClass.NEUTRAL
		&"rogue":
			return card.card_class == CardData.CardClass.ROGUE or card.card_class == CardData.CardClass.NEUTRAL
		&"mage":
			return card.card_class == CardData.CardClass.MAGE or card.card_class == CardData.CardClass.NEUTRAL
		_:
			return card.card_class == CardData.CardClass.NEUTRAL

func _deck_contains_card_name(deck: Array[CardData], card_name: String) -> bool:
	for deck_card in deck:
		if deck_card.card_name == card_name:
			return true
	return false

func _weighted_pick(cards: Array[CardData], is_elite: bool) -> CardData:
	## Rarity weights: normal = 60/30/10, elite = 35/40/25 (C/U/R).
	var total_weight: float = 0.0
	var weights: Array[float] = []
	for card in cards:
		var w: float
		match card.rarity:
			CardData.Rarity.COMMON:
				w = 35.0 if is_elite else 60.0
			CardData.Rarity.UNCOMMON:
				w = 40.0 if is_elite else 30.0
			CardData.Rarity.RARE:
				w = 25.0 if is_elite else 10.0
			_:
				w = 60.0
		weights.append(w)
		total_weight += w

	var roll: float = randf() * total_weight
	var cumulative: float = 0.0
	for i in range(cards.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			return cards[i]

	return cards[cards.size() - 1]
