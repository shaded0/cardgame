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
	var eligible: Array[CardData] = []
	var current_deck: Array[CardData] = GameManager.run_deck

	for card in all_cards:
		# Only offer class-matching or neutral cards.
		var matches_class: bool = false
		match class_id:
			&"soldier":
				matches_class = card.card_class == CardData.CardClass.SOLDIER or card.card_class == CardData.CardClass.NEUTRAL
			&"rogue":
				matches_class = card.card_class == CardData.CardClass.ROGUE or card.card_class == CardData.CardClass.NEUTRAL
			&"mage":
				matches_class = card.card_class == CardData.CardClass.MAGE or card.card_class == CardData.CardClass.NEUTRAL
			_:
				matches_class = card.card_class == CardData.CardClass.NEUTRAL

		if not matches_class:
			continue

		# Skip cards already in the run deck (no duplicate offerings).
		var already_in_deck: bool = false
		for deck_card in current_deck:
			if deck_card.card_name == card.card_name:
				already_in_deck = true
				break
		if already_in_deck:
			continue

		eligible.append(card)

	if eligible.is_empty():
		return []

	# Weighted random selection by rarity.
	var results: Array[CardData] = []
	for _i in range(count):
		if eligible.is_empty():
			break
		var pick: CardData = _weighted_pick(eligible, is_elite)
		results.append(pick)
		eligible.erase(pick)

	return results

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
