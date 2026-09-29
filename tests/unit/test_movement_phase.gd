extends GutTest


func _make_unit(player: int, position: Vector2, move_inches: float = 5.0) -> UnitInstance:
	var stats := AoSUnitStats.new()
	stats.move_inches = move_inches
	var unit := UnitInstance.new(stats, player)
	unit.position_inches = position
	return unit


func test_move_within_distance_succeeds() -> void:
	var ruleset := AoSRuleset.new()
	var tm := TurnManager.new(ruleset)
	var phase := AoSMovementPhase.new(tm)
	var unit := _make_unit(0, Vector2(0, 0), 5.0)

	var result := phase.try_move_unit(unit, Vector2(3, 4), [unit])  # distance 5

	assert_true(result.ok)
	assert_eq(unit.position_inches, Vector2(3, 4))
	assert_true(unit.has_moved)


func test_move_exceeding_distance_is_rejected_and_does_not_mutate() -> void:
	var ruleset := AoSRuleset.new()
	var tm := TurnManager.new(ruleset)
	var phase := AoSMovementPhase.new(tm)
	var unit := _make_unit(0, Vector2(0, 0), 5.0)

	var result := phase.try_move_unit(unit, Vector2(10, 0), [unit])

	assert_false(result.ok)
	assert_eq(result.reason, "exceeds_move")
	assert_eq(unit.position_inches, Vector2(0, 0))
	assert_false(unit.has_moved)


func test_move_out_of_engagement_range_is_rejected() -> void:
	var ruleset := AoSRuleset.new()
	var tm := TurnManager.new(ruleset)
	var phase := AoSMovementPhase.new(tm)
	var unit := _make_unit(0, Vector2(0, 0), 5.0)
	var enemy := _make_unit(1, Vector2(1, 0), 5.0)  # within AoS4's 3" engagement range

	var result := phase.try_move_unit(unit, Vector2(1, 1), [unit, enemy])

	assert_false(result.ok)
	assert_eq(result.reason, "engaged_must_fall_back")


func test_on_enter_resets_turn_flags_for_active_players_units() -> void:
	var ruleset := AoSRuleset.new()
	var tm := TurnManager.new(ruleset)
	var unit := _make_unit(0, Vector2(0, 0))
	unit.has_moved = true
	tm.match_state.units.append(unit)

	var phase := AoSMovementPhase.new(tm)
	phase.on_enter()

	assert_false(unit.has_moved)


func test_move_into_impassable_terrain_is_rejected_and_does_not_mutate() -> void:
	var ruleset := AoSRuleset.new()
	var tm := TurnManager.new(ruleset)
	var piece := TerrainPiece.new()
	piece.footprint_inches = Rect2(2, 2, 4, 4)
	piece.blocks_movement = true
	tm.match_state.terrain.append(piece)

	var phase := AoSMovementPhase.new(tm)
	var unit := _make_unit(0, Vector2(0, 0), 5.0)

	var result := phase.try_move_unit(unit, Vector2(3, 3), [unit])  # inside the 2,2 - 6,6 footprint

	assert_false(result.ok)
	assert_eq(result.reason, "blocked_by_terrain")
	assert_eq(unit.position_inches, Vector2(0, 0))


func test_move_near_but_outside_impassable_terrain_succeeds() -> void:
	var ruleset := AoSRuleset.new()
	var tm := TurnManager.new(ruleset)
	var piece := TerrainPiece.new()
	piece.footprint_inches = Rect2(2, 2, 4, 4)
	piece.blocks_movement = true
	tm.match_state.terrain.append(piece)

	var phase := AoSMovementPhase.new(tm)
	var unit := _make_unit(0, Vector2(0, 0), 5.0)

	var result := phase.try_move_unit(unit, Vector2(0, 4), [unit])  # outside the footprint

	assert_true(result.ok)


func test_normal_move_cannot_approach_within_engagement_range_of_a_new_enemy() -> void:
	var ruleset := AoSRuleset.new()
	var tm := TurnManager.new(ruleset)
	var phase := AoSMovementPhase.new(tm)
	var unit := _make_unit(0, Vector2(0, 0), 5.0)
	var enemy := _make_unit(1, Vector2(6, 0), 5.0)  # not engaged yet (6" apart)

	var result := phase.try_move_unit(unit, Vector2(4, 0), [unit, enemy])  # would end 2" away

	assert_false(result.ok)
	assert_eq(result.reason, "normal_move_cannot_approach_within_engagement_range")
	assert_eq(unit.position_inches, Vector2(0, 0))


func test_normal_move_that_stays_more_than_3_inches_from_enemy_succeeds() -> void:
	var ruleset := AoSRuleset.new()
	var tm := TurnManager.new(ruleset)
	var phase := AoSMovementPhase.new(tm)
	var unit := _make_unit(0, Vector2(0, 0), 5.0)
	var enemy := _make_unit(1, Vector2(10, 0), 5.0)

	var result := phase.try_move_unit(unit, Vector2(3, 0), [unit, enemy])  # ends 7" away

	assert_true(result.ok)


func test_unit_can_only_move_once_per_phase() -> void:
	var tm := TurnManager.new(AoSRuleset.new())
	var phase := AoSMovementPhase.new(tm)
	var unit := _make_unit(0, Vector2(0, 0), 5.0)

	assert_true(phase.try_move_unit(unit, Vector2(2, 0), [unit]).ok)
	var second := phase.try_move_unit(unit, Vector2(4, 0), [unit])

	assert_false(second.ok)
	assert_eq(second.reason, "already_moved")
	assert_eq(unit.position_inches, Vector2(2, 0))


func test_unit_can_move_again_after_has_moved_is_reset() -> void:
	var tm := TurnManager.new(AoSRuleset.new())
	var phase := AoSMovementPhase.new(tm)
	var unit := _make_unit(0, Vector2(0, 0), 5.0)
	phase.try_move_unit(unit, Vector2(2, 0), [unit])

	unit.has_moved = false  # what Undo does

	assert_true(phase.try_move_unit(unit, Vector2(3, 0), [unit]).ok)


func test_get_phase_name_is_movement_phase() -> void:
	var ruleset := AoSRuleset.new()
	var tm := TurnManager.new(ruleset)
	assert_eq(AoSMovementPhase.new(tm).get_phase_name(), &"Movement Phase")
	assert_eq(FortyKMovementPhase.new(tm).get_phase_name(), &"Movement Phase")


## Ported to 40k in Phase 5f: this check used to live only in
## AoSMovementPhase.can_move_to() but is identical in 40k 11th ed, so it was
## promoted to the shared MovementPhaseBase.can_move_to() instead.
func test_forty_k_normal_move_cannot_approach_within_engagement_range_of_a_new_enemy() -> void:
	var ruleset := FortyKRuleset.new()
	var tm := TurnManager.new(ruleset)
	var phase := FortyKMovementPhase.new(tm)
	var unit := _make_unit(0, Vector2(0, 0), 5.0)
	var enemy := _make_unit(1, Vector2(4.5, 0), 5.0)  # not engaged yet (40k's 1" range)

	var result := phase.try_move_unit(unit, Vector2(4, 0), [unit, enemy])  # would end 0.5" away

	assert_false(result.ok)
	assert_eq(result.reason, "normal_move_cannot_approach_within_engagement_range")
	assert_eq(unit.position_inches, Vector2(0, 0))


func test_forty_k_normal_move_that_stays_out_of_engagement_range_succeeds() -> void:
	var ruleset := FortyKRuleset.new()
	var tm := TurnManager.new(ruleset)
	var phase := FortyKMovementPhase.new(tm)
	var unit := _make_unit(0, Vector2(0, 0), 5.0)
	var enemy := _make_unit(1, Vector2(10, 0), 5.0)

	var result := phase.try_move_unit(unit, Vector2(3, 0), [unit, enemy])  # ends 7" away

	assert_true(result.ok)
