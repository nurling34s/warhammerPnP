extends GutTest


func _make_stats() -> AoSUnitStats:
	var stats := AoSUnitStats.new()
	stats.models_per_unit = 5
	stats.move_inches = 5.0
	return stats


func test_init_sets_models_alive_from_stats() -> void:
	var unit := UnitInstance.new(_make_stats(), 0)
	assert_eq(unit.models_alive, 5)
	assert_eq(unit.owner_player, 0)
	assert_eq(unit.is_destroyed, false)


func test_remaining_move_inches_matches_stats() -> void:
	var unit := UnitInstance.new(_make_stats(), 0)
	assert_eq(unit.remaining_move_inches(), 5.0)


func test_reset_turn_flags_clears_all_flags() -> void:
	var unit := UnitInstance.new(_make_stats(), 0)
	unit.has_moved = true
	unit.has_run_or_advanced = true
	unit.has_charged = true
	unit.has_fallen_back = true

	unit.reset_turn_flags()

	assert_false(unit.has_moved)
	assert_false(unit.has_run_or_advanced)
	assert_false(unit.has_charged)
	assert_false(unit.has_fallen_back)


func test_match_state_filters_by_owner_and_alive() -> void:
	var state := MatchState.new()
	var p0_alive := UnitInstance.new(_make_stats(), 0)
	var p0_dead := UnitInstance.new(_make_stats(), 0)
	p0_dead.is_destroyed = true
	var p1_alive := UnitInstance.new(_make_stats(), 1)
	state.units = [p0_alive, p0_dead, p1_alive]

	assert_eq(state.units_for_player(0), [p0_alive])
	assert_eq(state.enemy_units_of(p0_alive), [p1_alive])
