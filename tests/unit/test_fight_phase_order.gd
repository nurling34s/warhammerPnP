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


func _make_unit(player: int, position: Vector2) -> UnitInstance:
	var stats := AoSUnitStats.new()
	var unit := UnitInstance.new(stats, player)
	unit.position_inches = position
	return unit


func test_chargers_activate_before_non_chargers() -> void:
	var ruleset := AoSRuleset.new()
	var tm := TurnManager.new(ruleset)
	var p0 := _make_unit(0, Vector2(0, 0))
	var p1 := _make_unit(1, Vector2(1, 0))  # within AoS4's 3" engagement range
	p1.has_charged = true
	tm.match_state.units = [p0, p1]

	var phase := AoSFightPhase.new(tm)
	phase.on_enter()

	assert_eq(phase.activation_queue()[0], p1, "the charging unit should activate first")


func test_non_engaged_units_are_excluded_from_activation_order() -> void:
	var ruleset := AoSRuleset.new()
	var tm := TurnManager.new(ruleset)
	var engaged_a := _make_unit(0, Vector2(0, 0))
	var engaged_b := _make_unit(1, Vector2(1, 0))
	var far_away := _make_unit(0, Vector2(50, 0))
	tm.match_state.units = [engaged_a, engaged_b, far_away]

	var phase := AoSFightPhase.new(tm)
	phase.on_enter()

	assert_false(phase.activation_queue().has(far_away))
	assert_eq(phase.activation_queue().size(), 2)


func test_next_to_fight_drains_the_queue() -> void:
	var ruleset := AoSRuleset.new()
	var tm := TurnManager.new(ruleset)
	var a := _make_unit(0, Vector2(0, 0))
	var b := _make_unit(1, Vector2(1, 0))
	tm.match_state.units = [a, b]

	var phase := AoSFightPhase.new(tm)
	phase.on_enter()

	assert_not_null(phase.next_to_fight())
	assert_not_null(phase.next_to_fight())
	assert_null(phase.next_to_fight())


func test_declare_pile_in_moves_unit_toward_target_up_to_3_inches() -> void:
	var ruleset := AoSRuleset.new()
	var tm := TurnManager.new(ruleset)
	var mover := _make_unit(0, Vector2(0, 0))
	var target := _make_unit(1, Vector2(10, 0))

	var phase := AoSFightPhase.new(tm)
	var result := phase.declare_pile_in(mover, target)

	assert_true(result.ok)
	assert_eq(mover.position_inches, Vector2(3, 0))


func test_declare_pile_in_stops_short_if_target_is_closer_than_pile_in_distance() -> void:
	var ruleset := AoSRuleset.new()
	var tm := TurnManager.new(ruleset)
	var mover := _make_unit(0, Vector2(0, 0))
	var target := _make_unit(1, Vector2(1, 0))

	var phase := AoSFightPhase.new(tm)
	var result := phase.declare_pile_in(mover, target)

	assert_true(result.ok)
	assert_eq(mover.position_inches, Vector2(1, 0))


func test_can_fight_requires_engagement_range() -> void:
	var ruleset := AoSRuleset.new()
	var tm := TurnManager.new(ruleset)
	var phase := AoSFightPhase.new(tm)
	var attacker := _make_unit(0, Vector2(0, 0))
	var far_target := _make_unit(1, Vector2(10, 0))

	var result := phase.can_fight(attacker, far_target)
	assert_false(result.ok)
	assert_eq(result.reason, "out_of_engagement_range")


func test_declare_fight_resolves_attack_when_in_range() -> void:
	var ruleset := AoSRuleset.new()
	var tm := TurnManager.new(ruleset)
	var phase := AoSFightPhase.new(tm)
	var attacker := _make_unit(0, Vector2(0, 0))
	var target := _make_unit(1, Vector2(1, 0))

	var weapon := WeaponProfile.new()
	weapon.attacks = "1"
	weapon.to_hit_stat = 2
	var dice := ScriptedDice.new([6, 1])
	var resolver := AttackResolver.new(ruleset, dice)

	var result := phase.declare_fight(attacker, weapon, target, resolver)
	assert_true(result.ok)
	assert_not_null(result.outcome)


func test_get_phase_name_differs_per_ruleset() -> void:
	var tm_aos := TurnManager.new(AoSRuleset.new())
	var tm_40k := TurnManager.new(FortyKRuleset.new())
	assert_eq(AoSFightPhase.new(tm_aos).get_phase_name(), &"Combat Phase")
	assert_eq(FortyKFightPhase.new(tm_40k).get_phase_name(), &"Fight Phase")
