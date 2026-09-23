extends GutTest

## Same scripted-dice pattern as test_dice_roller.gd.
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


func _make_aos_unit(bravery: int = 6) -> UnitInstance:
	var stats := AoSUnitStats.new()
	stats.bravery = bravery
	stats.models_per_unit = 3
	return UnitInstance.new(stats, 0)


func _make_40k_unit(leadership: int = 6) -> UnitInstance:
	var stats := FortyKUnitStats.new()
	stats.leadership = leadership
	stats.models_per_unit = 3
	return UnitInstance.new(stats, 0)


func test_aos_battleshock_auto_passes_with_no_models_lost() -> void:
	var ruleset := AoSRuleset.new()
	var unit := _make_aos_unit(6)
	var dice := ScriptedDice.new([])
	assert_true(ruleset.resolve_battleshock(unit, 0, dice))


func test_aos_battleshock_fails_when_roll_plus_losses_exceeds_bravery() -> void:
	var ruleset := AoSRuleset.new()
	var unit := _make_aos_unit(6)
	var dice := ScriptedDice.new([5])  # 5 + 2 lost = 7 > bravery 6
	assert_false(ruleset.resolve_battleshock(unit, 2, dice))


func test_aos_battleshock_passes_when_total_within_bravery() -> void:
	var ruleset := AoSRuleset.new()
	var unit := _make_aos_unit(6)
	var dice := ScriptedDice.new([3])  # 3 + 1 lost = 4 <= bravery 6
	assert_true(ruleset.resolve_battleshock(unit, 1, dice))


func test_forty_k_battleshock_fails_when_2d6_exceeds_leadership() -> void:
	var ruleset := FortyKRuleset.new()
	var unit := _make_40k_unit(7)
	var dice := ScriptedDice.new([5, 4])  # sum 9 > leadership 7
	assert_false(ruleset.resolve_battleshock(unit, 1, dice))


func test_forty_k_battleshock_passes_when_2d6_within_leadership() -> void:
	var ruleset := FortyKRuleset.new()
	var unit := _make_40k_unit(9)
	var dice := ScriptedDice.new([3, 4])  # sum 7 <= leadership 9
	assert_true(ruleset.resolve_battleshock(unit, 1, dice))


func test_aos_end_phase_removes_one_model_on_failed_battleshock() -> void:
	var ruleset := AoSRuleset.new()
	var tm := TurnManager.new(ruleset)
	var unit := _make_aos_unit(6)
	unit.models_lost_this_turn = 2
	tm.match_state.units.append(unit)

	var phase := AoSEndPhase.new(tm)
	var dice := ScriptedDice.new([6])  # 6 + 2 = 8 > bravery 6 -> fail

	phase.resolve_battleshock_for_unit(unit, dice)

	assert_eq(unit.models_alive, 2, "should have lost one additional model")
	assert_true(unit.battleshock_failed_this_turn)


func test_aos_end_phase_skips_units_with_no_losses() -> void:
	var ruleset := AoSRuleset.new()
	var tm := TurnManager.new(ruleset)
	var unit := _make_aos_unit(6)
	var dice := ScriptedDice.new([])  # would error if consumed

	var phase := AoSEndPhase.new(tm)
	phase.resolve_battleshock_for_unit(unit, dice)

	assert_eq(unit.models_alive, 3)
	assert_false(unit.battleshock_failed_this_turn)


func test_forty_k_battle_shock_phase_removes_one_model_on_failure() -> void:
	var ruleset := FortyKRuleset.new()
	var tm := TurnManager.new(ruleset)
	var unit := _make_40k_unit(6)
	unit.models_lost_this_turn = 1
	tm.match_state.units.append(unit)

	var phase := FortyKBattleShockPhase.new(tm)
	var dice := ScriptedDice.new([5, 5])  # sum 10 > leadership 6 -> fail

	phase.resolve_battleshock_for_unit(unit, dice)

	assert_eq(unit.models_alive, 2)
	assert_true(unit.battleshock_failed_this_turn)


func test_get_phase_name_differs_per_ruleset() -> void:
	var tm_aos := TurnManager.new(AoSRuleset.new())
	var tm_40k := TurnManager.new(FortyKRuleset.new())
	assert_eq(AoSEndPhase.new(tm_aos).get_phase_name(), &"End Phase")
	assert_eq(FortyKBattleShockPhase.new(tm_40k).get_phase_name(), &"Battle-shock Phase")
