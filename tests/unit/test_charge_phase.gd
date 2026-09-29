extends GutTest

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
	stats.models_per_unit = 5
	stats.health_per_model = 1
	var unit := UnitInstance.new(stats, player)
	unit.position_inches = position
	return unit


func _make_phase(ruleset: RulesetProvider = null) -> ChargePhaseBase:
	var tm := TurnManager.new(ruleset if ruleset else AoSRuleset.new())
	return ChargePhaseBase.new(tm)


func test_successful_charge_moves_unit_into_engagement_range_and_sets_has_charged() -> void:
	var phase := _make_phase()
	var unit := _make_unit(0, Vector2(0, 0))
	var enemy := _make_unit(1, Vector2(10, 0))  # nearest models ~8" apart, needs 5" to reach AoS's 3"

	var result := phase.declare_charge(unit, enemy, [unit, enemy], ScriptedDice.new([3, 3]))  # rolls 6"

	assert_true(result.ok)
	assert_eq(result.distance_rolled, 6)
	assert_true(unit.has_charged)
	assert_true(unit.has_attempted_charge)
	# Nearest models were 8" apart and the roll (6") is the limit, so it stops 2" short.
	assert_almost_eq(unit.nearest_model_distance_to(enemy), 2.0, 0.001)
	assert_eq(unit.position_inches, Vector2(6, 0))
	assert_true(phase.turn_manager.ruleset.is_in_engagement_range(unit, [unit, enemy]))


func test_charge_with_a_long_roll_stops_at_the_contact_gap() -> void:
	var phase := _make_phase(FortyKRuleset.new())
	var unit := _make_unit(0, Vector2(0, 0))
	var enemy := _make_unit(1, Vector2(10, 0))

	phase.declare_charge(unit, enemy, [unit, enemy], ScriptedDice.new([6, 6]))  # 12" — far more than needed

	assert_almost_eq(unit.nearest_model_distance_to(enemy), MovementMath.CONTACT_GAP_INCHES, 0.001)
	assert_true(phase.turn_manager.ruleset.is_in_engagement_range(unit, [unit, enemy]))


func test_failed_charge_roll_leaves_unit_in_place_but_uses_up_the_attempt() -> void:
	var phase := _make_phase()
	var unit := _make_unit(0, Vector2(0, 0))
	var enemy := _make_unit(1, Vector2(10, 0))

	var result := phase.declare_charge(unit, enemy, [unit, enemy], ScriptedDice.new([1, 2]))  # rolls 3" < 5" needed

	assert_false(result.ok)
	assert_eq(result.reason, "failed_charge_roll")
	assert_eq(result.distance_rolled, 3)
	assert_false(unit.has_charged, "a failed charge must not grant fight-first priority")
	assert_true(unit.has_attempted_charge)
	assert_eq(unit.position_inches, Vector2(0, 0))


func test_unit_cannot_attempt_a_second_charge_in_the_same_phase() -> void:
	var phase := _make_phase()
	var unit := _make_unit(0, Vector2(0, 0))
	var enemy := _make_unit(1, Vector2(10, 0))
	phase.declare_charge(unit, enemy, [unit, enemy], ScriptedDice.new([1, 2]))

	var result := phase.declare_charge(unit, enemy, [unit, enemy], ScriptedDice.new([6, 6]))

	assert_false(result.ok)
	assert_eq(result.reason, "already_attempted_charge")


func test_cannot_charge_when_already_in_engagement_range() -> void:
	var phase := _make_phase()
	var unit := _make_unit(0, Vector2(0, 0))
	var enemy := _make_unit(1, Vector2(4, 0))  # nearest models ~2" apart, inside AoS's 3"

	var result := phase.can_declare_charge(unit, enemy, [unit, enemy])

	assert_false(result.ok)
	assert_eq(result.reason, "already_engaged")


func test_cannot_charge_after_falling_back() -> void:
	var phase := _make_phase()
	var unit := _make_unit(0, Vector2(0, 0))
	var enemy := _make_unit(1, Vector2(10, 0))
	unit.has_fallen_back = true

	var result := phase.can_declare_charge(unit, enemy, [unit, enemy])

	assert_false(result.ok)
	assert_eq(result.reason, "cannot_charge_after_falling_back")


func test_cannot_charge_a_friendly_unit() -> void:
	var phase := _make_phase()
	var unit := _make_unit(0, Vector2(0, 0))
	var friend := _make_unit(0, Vector2(10, 0))

	var result := phase.can_declare_charge(unit, friend, [unit, friend])

	assert_false(result.ok)
	assert_eq(result.reason, "invalid_target")


func test_charge_ending_inside_impassable_terrain_is_rejected() -> void:
	var phase := _make_phase()
	var piece := TerrainPiece.new()
	piece.footprint_inches = Rect2(5, -1, 3, 2)  # contains the (6, 0) destination
	piece.blocks_movement = true
	phase.turn_manager.match_state.terrain.append(piece)
	var unit := _make_unit(0, Vector2(0, 0))
	var enemy := _make_unit(1, Vector2(10, 0))

	var result := phase.declare_charge(unit, enemy, [unit, enemy], ScriptedDice.new([3, 3]))

	assert_false(result.ok)
	assert_eq(result.reason, "blocked_by_terrain")
	assert_false(unit.has_charged)
	assert_eq(unit.position_inches, Vector2(0, 0))


func test_charge_ends_with_the_bases_touching_and_still_in_engagement_range() -> void:
	for ruleset in [AoSRuleset.new(), FortyKRuleset.new()]:
		var phase := _make_phase(ruleset)
		var unit := _make_unit(0, Vector2(0, 0))
		var enemy := _make_unit(1, Vector2(10, 0))
		unit.stats.base_size_mm = 32.0
		enemy.stats.base_size_mm = 32.0

		var result := phase.declare_charge(unit, enemy, [unit, enemy], ScriptedDice.new([6, 6]))

		assert_true(result.ok)
		assert_almost_eq(unit.nearest_edge_distance_to(enemy), 0.0, 0.001, "bases touch")
		assert_true(ruleset.is_in_engagement_range(unit, [unit, enemy]), "touching bases are engaged (40k's 1\" is edge-to-edge)")


func test_forty_k_charge_uses_its_own_engagement_range() -> void:
	var phase := _make_phase(FortyKRuleset.new())
	var unit := _make_unit(0, Vector2(0, 0))
	var enemy := _make_unit(1, Vector2(10, 0))  # nearest ~8", needs 7" to reach 40k's 1"

	var too_short := phase.declare_charge(unit, enemy, [unit, enemy], ScriptedDice.new([3, 3]))  # 6" < 7"

	assert_false(too_short.ok)
	assert_eq(too_short.reason, "failed_charge_roll")


func test_charge_phase_names() -> void:
	assert_eq(AoSChargePhase.new(TurnManager.new(AoSRuleset.new())).get_phase_name(), &"Charge Phase")
	assert_eq(FortyKChargePhase.new(TurnManager.new(FortyKRuleset.new())).get_phase_name(), &"Charge Phase")
