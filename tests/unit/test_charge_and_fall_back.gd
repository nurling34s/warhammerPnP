extends GutTest

## Same scripted-dice pattern as test_dice_roller.gd: a DiceRoller stand-in
## that returns a fixed sequence so charge-distance math is exactly
## assertable rather than merely range-checked.
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


func _make_unit(player: int, position: Vector2 = Vector2.ZERO) -> UnitInstance:
	var stats := AoSUnitStats.new()
	var unit := UnitInstance.new(stats, player)
	unit.position_inches = position
	return unit


func test_aos_charge_distance_sums_two_d6() -> void:
	var ruleset := AoSRuleset.new()
	var dice := ScriptedDice.new([4, 5])
	assert_eq(ruleset.roll_charge_distance(_make_unit(0), dice), 9)


func test_forty_k_charge_distance_sums_two_d6() -> void:
	var ruleset := FortyKRuleset.new()
	var dice := ScriptedDice.new([6, 6])
	assert_eq(ruleset.roll_charge_distance(_make_unit(0), dice), 12)


func test_unit_engaged_cannot_move_without_falling_back() -> void:
	var ruleset := AoSRuleset.new()
	var tm := TurnManager.new(ruleset)
	var phase := AoSMovementPhase.new(tm)
	var unit := _make_unit(0, Vector2(0, 0))
	var enemy := _make_unit(1, Vector2(1, 0))

	var result := phase.try_move_unit(unit, Vector2(1, 1), [unit, enemy])

	assert_false(result.ok)
	assert_eq(result.reason, "engaged_must_fall_back")


## Distinct from _make_unit(): pre-sets health_per_model on the stats before
## constructing the UnitInstance, since model_wounds_remaining is built once
## at _init() time — mutating stats.health_per_model afterward wouldn't
## resize it.
func _make_tanky_unit(player: int, position: Vector2) -> UnitInstance:
	var stats := AoSUnitStats.new()
	stats.move_inches = 5.0
	stats.health_per_model = 10  # survive the D3 self-damage roll in these tests
	var unit := UnitInstance.new(stats, player)
	unit.position_inches = position
	return unit


func test_declared_fall_back_lets_engaged_unit_move() -> void:
	var ruleset := AoSRuleset.new()
	var tm := TurnManager.new(ruleset)
	var phase := AoSMovementPhase.new(tm)
	var unit := _make_tanky_unit(0, Vector2(0, 0))
	var enemy := _make_unit(1, Vector2(1, 0))

	phase.declare_fall_back(unit, ScriptedDice.new([2]))
	var result := phase.try_move_unit(unit, Vector2(4, 0), [unit, enemy])

	assert_true(result.ok)
	assert_eq(unit.position_inches, Vector2(4, 0))


func test_declared_fall_back_deals_d3_self_damage() -> void:
	var ruleset := AoSRuleset.new()
	var tm := TurnManager.new(ruleset)
	var phase := AoSMovementPhase.new(tm)
	var unit := _make_tanky_unit(0, Vector2(0, 0))

	phase.declare_fall_back(unit, ScriptedDice.new([2]))

	assert_eq(unit.model_wounds_remaining[0], 8)  # 10 - 2 self-inflicted damage
	assert_true(unit.has_fallen_back)


func test_reset_turn_flags_clears_fallen_back_for_next_turn() -> void:
	var unit := _make_unit(0)
	unit.has_fallen_back = true
	unit.reset_turn_flags()
	assert_false(unit.has_fallen_back)
