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


## Builds a phase over `units` (all added to the match) with `active` as the
## active player, and runs on_enter().
func _start_phase(phase_script: GDScript, ruleset: RulesetProvider, units: Array, active: int = 0) -> FightPhaseBase:
	var tm := TurnManager.new(ruleset)
	tm.active_player = active
	for unit in units:
		tm.match_state.units.append(unit)
	var phase: FightPhaseBase = phase_script.new(tm)
	phase.on_enter()
	return phase


func test_aos_active_player_activates_first_even_against_a_charger() -> void:
	var p0 := _make_unit(0, Vector2(0, 0))
	var p1 := _make_unit(1, Vector2(1, 0))  # within AoS4's 3" engagement range
	p1.has_charged = true

	var phase := _start_phase(AoSFightPhase, AoSRuleset.new(), [p0, p1], 0)

	assert_eq(phase.eligible_units(), [p0], "AoS4 gives chargers no priority; the active player picks first")


func test_forty_k_opponent_activates_first_without_chargers() -> void:
	var p0 := _make_unit(0, Vector2(0, 0))
	var p1 := _make_unit(1, Vector2(0.5, 0))  # within 40k's 1" engagement range

	var phase := _start_phase(FortyKFightPhase, FortyKRuleset.new(), [p0, p1], 0)

	assert_eq(phase.eligible_units(), [p1])


func test_forty_k_active_players_chargers_fight_first() -> void:
	var p0 := _make_unit(0, Vector2(0, 0))
	var p1 := _make_unit(1, Vector2(0.5, 0))
	p0.has_charged = true

	var phase := _start_phase(FortyKFightPhase, FortyKRuleset.new(), [p0, p1], 0)

	assert_eq(phase.eligible_units(), [p0])


func test_stale_has_charged_of_the_non_active_player_gives_no_priority() -> void:
	var p0 := _make_unit(0, Vector2(0, 0))
	var p1 := _make_unit(1, Vector2(0.5, 0))
	p1.has_charged = true  # left over from p1's own previous turn

	var phase := _start_phase(FortyKFightPhase, FortyKRuleset.new(), [p0, p1], 0)

	assert_eq(phase.eligible_units(), [p1], "no active-player chargers, so the normal opponent-first order applies")


func test_units_alternate_between_players_after_each_fight() -> void:
	var a0 := _make_unit(0, Vector2(0, 0))
	var b0 := _make_unit(0, Vector2(0, 5))
	var a1 := _make_unit(1, Vector2(1, 0))
	var b1 := _make_unit(1, Vector2(1, 5))
	var phase := _start_phase(AoSFightPhase, AoSRuleset.new(), [a0, b0, a1, b1], 0)
	var weapon := WeaponProfile.new()
	weapon.attacks = "1"
	weapon.to_hit_stat = 7  # can never hit, so nobody dies and the queue is undisturbed
	var resolver := AttackResolver.new(AoSRuleset.new(), ScriptedDice.new([1, 1, 1, 1]))

	assert_eq(phase.eligible_units(), [a0, b0])
	phase.declare_fight(a0, weapon, a1, resolver)
	assert_eq(phase.eligible_units(), [a1, b1])
	phase.declare_fight(a1, weapon, a0, resolver)
	assert_eq(phase.eligible_units(), [b0])
	phase.declare_fight(b0, weapon, b1, resolver)
	assert_eq(phase.eligible_units(), [b1])


func test_non_engaged_units_are_not_pending() -> void:
	var engaged_a := _make_unit(0, Vector2(0, 0))
	var engaged_b := _make_unit(1, Vector2(1, 0))
	var far_away := _make_unit(0, Vector2(50, 0))

	var phase := _start_phase(AoSFightPhase, AoSRuleset.new(), [engaged_a, engaged_b, far_away])

	assert_false(phase.pending_units().has(far_away))
	assert_eq(phase.pending_units().size(), 2)


func test_on_enter_resets_has_fought_for_both_players() -> void:
	var p0 := _make_unit(0, Vector2(0, 0))
	var p1 := _make_unit(1, Vector2(1, 0))
	p0.has_fought = true
	p1.has_fought = true

	_start_phase(AoSFightPhase, AoSRuleset.new(), [p0, p1], 0)

	assert_false(p0.has_fought)
	assert_false(p1.has_fought)


func test_fighting_out_of_turn_is_refused() -> void:
	var p0 := _make_unit(0, Vector2(0, 0))
	var p1 := _make_unit(1, Vector2(1, 0))
	var phase := _start_phase(AoSFightPhase, AoSRuleset.new(), [p0, p1], 0)

	var result := phase.can_fight(p1, p0)

	assert_false(result.ok)
	assert_eq(result.reason, "not_this_units_turn_to_fight")


func test_pile_in_is_refused_when_not_in_engagement_range() -> void:
	var mover := _make_unit(0, Vector2(0, 0))
	var target := _make_unit(1, Vector2(10, 0))
	var phase := _start_phase(AoSFightPhase, AoSRuleset.new(), [mover, target])

	var result := phase.declare_pile_in(mover, target)

	assert_false(result.ok)
	assert_eq(result.reason, "not_engaged")
	assert_eq(mover.position_inches, Vector2(0, 0))


func test_pile_in_closes_to_contact_gap_without_overlapping() -> void:
	var mover := _make_unit(0, Vector2(0, 0))
	var target := _make_unit(1, Vector2(2, 0))  # 2" apart, inside AoS4's 3"
	var phase := _start_phase(AoSFightPhase, AoSRuleset.new(), [mover, target])

	var result := phase.declare_pile_in(mover, target)

	assert_true(result.ok)
	assert_almost_eq(mover.nearest_model_distance_to(target), MovementMath.CONTACT_GAP_INCHES, 0.001)


func _make_based_unit(player: int, position: Vector2) -> UnitInstance:
	var stats := AoSUnitStats.new()
	stats.base_size_mm = 32.0
	var unit := UnitInstance.new(stats, player)
	unit.position_inches = position
	return unit


func test_pile_in_ends_with_the_bases_touching_not_overlapping() -> void:
	var mover := _make_based_unit(0, Vector2(0, 0))
	var target := _make_based_unit(1, Vector2(3, 0))  # ~1.7" between the base edges, inside AoS4's 3"
	var phase := _start_phase(AoSFightPhase, AoSRuleset.new(), [mover, target])

	phase.declare_pile_in(mover, target)

	var touching_centres := 32.0 / 25.4  # two 32mm bases side by side
	assert_almost_eq(mover.position_inches.distance_to(target.position_inches), touching_centres, 0.001)
	assert_almost_eq(mover.nearest_edge_distance_to(target), 0.0, 0.001)


func test_pile_in_does_not_move_a_unit_whose_base_already_touches() -> void:
	var touching_centres := 32.0 / 25.4
	var mover := _make_based_unit(0, Vector2(0, 0))
	var target := _make_based_unit(1, Vector2(touching_centres, 0))
	var phase := _start_phase(FortyKFightPhase, FortyKRuleset.new(), [mover, target])

	phase.declare_pile_in(mover, target)

	assert_eq(mover.position_inches, Vector2(0, 0))


func test_can_fight_requires_engagement_range() -> void:
	var attacker := _make_unit(0, Vector2(0, 0))
	var far_target := _make_unit(1, Vector2(10, 0))
	var phase := _start_phase(AoSFightPhase, AoSRuleset.new(), [attacker, far_target])

	var result := phase.can_fight(attacker, far_target)

	assert_false(result.ok)
	assert_eq(result.reason, "out_of_engagement_range")


func test_declare_fight_resolves_attack_and_uses_up_the_activation() -> void:
	var ruleset := AoSRuleset.new()
	var attacker := _make_unit(0, Vector2(0, 0))
	var target := _make_unit(1, Vector2(1, 0))
	var phase := _start_phase(AoSFightPhase, ruleset, [attacker, target])

	var weapon := WeaponProfile.new()
	weapon.attacks = "1"
	weapon.to_hit_stat = 2
	var resolver := AttackResolver.new(ruleset, ScriptedDice.new([6, 1]))

	var result := phase.declare_fight(attacker, weapon, target, resolver)

	assert_true(result.ok)
	assert_not_null(result.outcome)
	assert_true(attacker.has_fought)
	assert_false(phase.pending_units().has(attacker), "a fought unit is no longer pending")
	assert_eq(phase.can_fight(attacker, target).reason, "already_fought")


func test_get_phase_name_differs_per_ruleset() -> void:
	var tm_aos := TurnManager.new(AoSRuleset.new())
	var tm_40k := TurnManager.new(FortyKRuleset.new())
	assert_eq(AoSFightPhase.new(tm_aos).get_phase_name(), &"Combat Phase")
	assert_eq(FortyKFightPhase.new(tm_40k).get_phase_name(), &"Fight Phase")
