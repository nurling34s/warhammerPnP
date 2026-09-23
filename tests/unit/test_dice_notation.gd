extends GutTest

## Same scripted-dice pattern as test_dice_roller.gd/test_charge_and_fall_back.gd.
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


func test_parse_flat_number() -> void:
	var parsed := DiceNotation.parse("3")
	assert_eq(parsed.fixed, 3)
	assert_eq(parsed.dice_count, 0)


func test_parse_single_die_without_explicit_count() -> void:
	var parsed := DiceNotation.parse("D3")
	assert_eq(parsed.dice_count, 1)
	assert_eq(parsed.dice_sides, 3)


func test_parse_multiple_dice() -> void:
	var parsed := DiceNotation.parse("2D6")
	assert_eq(parsed.dice_count, 2)
	assert_eq(parsed.dice_sides, 6)


func test_parse_is_case_insensitive() -> void:
	var parsed := DiceNotation.parse("2d6")
	assert_eq(parsed.dice_count, 2)
	assert_eq(parsed.dice_sides, 6)


func test_roll_flat_number_ignores_dice() -> void:
	var dice := ScriptedDice.new([])
	assert_eq(DiceNotation.roll("5", dice), 5)


func test_roll_single_die() -> void:
	var dice := ScriptedDice.new([2])
	assert_eq(DiceNotation.roll("D3", dice), 2)


func test_roll_multiple_dice_sums_all() -> void:
	var dice := ScriptedDice.new([3, 5])
	assert_eq(DiceNotation.roll("2D6", dice), 8)
