extends "res://tests/support/test_case.gd"

const RewardScreenScript = preload("res://scripts/ui/card_reward_screen.gd")
const RestScreenScript = preload("res://scripts/ui/rest_screen.gd")
const Factory = preload("res://tests/support/test_factory.gd")

func test_reward_screen_skip_emits_once_even_if_triggered_twice() -> void:
	var reward_screen: CardRewardScreen = RewardScreenScript.new()
	var skipped_count := 0
	reward_screen.rewards_skipped.connect(func() -> void:
		skipped_count += 1
	)
	root.add_child(reward_screen)
	reward_screen._card_options = [Factory.make_card("Strike")]
	reward_screen._build_ui()

	reward_screen._on_skip()
	reward_screen._on_skip()

	assert_eq(skipped_count, 1, "Reward screens should be one-shot so repeated skip input cannot fire twice during the exit tween.")

func test_rest_screen_complete_emits_once_even_if_called_twice() -> void:
	var rest_screen: RestScreen = RestScreenScript.new()
	var complete_count := 0
	rest_screen.rest_completed.connect(func() -> void:
		complete_count += 1
	)
	root.add_child(rest_screen)

	rest_screen._complete()
	rest_screen._complete()

	assert_eq(complete_count, 1, "Rest screens should only complete once so quick double input cannot spend the rest-room action twice.")
