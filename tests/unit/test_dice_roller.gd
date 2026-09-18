extends GutTest

const DiceRoller = preload("res://core/dice/dice_roller.gd")
const ModifierChain = preload("res://core/dice/modifier_chain.gd")


## A DiceRoller stand-in that returns a scripted sequence instead of real random
## values, so ModifierChain tests can assert exact outcomes.
class ScriptedDice:
	extends DiceRoller

	var _queue: Array[int] = []

	func _init(sequence: Array[int]) -> void:
		_queue = sequence.duplicate()

	func roll(n: int, sides: int = 6) -> Array[int]:
		var out: Array[int] = []
		for _i in n:
			out.append(roll_single(sides))
		return out

	func roll_single(_sides: int = 6) -> int:
		return _queue.pop_front()


func test_seeded_rolls_are_reproducible() -> void:
	var a := DiceRoller.new(1234)
	var b := DiceRoller.new(1234)
	assert_eq(a.roll(10), b.roll(10), "same seed must produce the same sequence of rolls")


func test_roll_values_are_within_die_range() -> void:
	var dice := DiceRoller.new(42)
	for value in dice.roll(200, 6):
		assert_between(value, 1, 6, "a D6 roll must land between 1 and 6")


func test_unmodified_one_always_fails_even_with_positive_modifier() -> void:
	var dice := ScriptedDice.new([1])
	var chain := ModifierChain.new()
	chain.flat_modifier = 5
	var result := chain.apply(dice, 4, 1)
	assert_eq(result.successes, 0, "an unmodified 1 must always fail regardless of modifiers")


func test_unmodified_six_always_succeeds_even_against_high_target() -> void:
	var dice := ScriptedDice.new([6])
	var chain := ModifierChain.new()
	var result := chain.apply(dice, 4, 1)
	assert_eq(result.successes, 1, "an unmodified 6 must always succeed")


func test_flat_modifier_shifts_non_extreme_rolls() -> void:
	var dice := ScriptedDice.new([3])
	var chain := ModifierChain.new()
	chain.flat_modifier = 1
	var result := chain.apply(dice, 4, 1)
	assert_eq(result.modified_rolls[0], 4)
	assert_eq(result.successes, 1, "3 modified to 4 should meet a target of 4+")


func test_reroll_ones_rerolls_only_natural_ones() -> void:
	var dice := ScriptedDice.new([1, 5])
	var chain := ModifierChain.new()
	chain.reroll_rule = ModifierChain.Reroll.ONES
	var result := chain.apply(dice, 4, 1)
	assert_eq(result.final_rolls[0], 5, "a natural 1 should be rerolled into the next scripted value")


func test_crit_threshold_counts_unmodified_high_rolls() -> void:
	var dice := ScriptedDice.new([6, 3])
	var chain := ModifierChain.new()
	chain.crit_threshold = 6
	var result := chain.apply(dice, 4, 2)
	assert_eq(result.critical_successes, 1, "only the unmodified 6 should count as a crit")
