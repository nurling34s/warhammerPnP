## AoS4 has no Battleshock at all (warhammer_age_of_sigmar_4.md section 1) —
## this file used to also cover AoSRuleset.resolve_battleshock()/AoSEndPhase's
## battleshock consequence, which have been removed. Only 40k 11th ed still
## has the mechanic.
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


func _make_40k_unit(leadership: int = 6) -> UnitInstance:
	var stats := FortyKUnitStats.new()
	stats.leadership = leadership
	stats.models_per_unit = 3
	return UnitInstance.new(stats, 0)


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
