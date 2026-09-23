extends GutTest


func _make_stats(models: int = 5, health_per_model: int = 1) -> AoSUnitStats:
	var stats := AoSUnitStats.new()
	stats.models_per_unit = models
	stats.health_per_model = health_per_model
	stats.move_inches = 5.0
	return stats


func test_init_sets_models_alive_from_stats() -> void:
	var unit := UnitInstance.new(_make_stats(), 0)
	assert_eq(unit.models_alive, 5)
	assert_eq(unit.owner_player, 0)
	assert_eq(unit.is_destroyed, false)


func test_init_populates_model_wounds_remaining_from_health_per_model() -> void:
	var unit := UnitInstance.new(_make_stats(3, 2), 0)
	assert_eq(unit.model_wounds_remaining, [2, 2, 2])


func test_apply_damage_partial_wound_does_not_kill_model() -> void:
	var unit := UnitInstance.new(_make_stats(3, 2), 0)
	var leftover := unit.apply_damage_to_next_model(1)
	assert_eq(leftover, 0)
	assert_eq(unit.model_wounds_remaining, [1, 2, 2])
	assert_eq(unit.models_alive, 3)
	assert_eq(unit.models_lost_this_turn, 0)


func test_apply_damage_kills_model_and_spills_remainder() -> void:
	var unit := UnitInstance.new(_make_stats(3, 2), 0)
	var leftover := unit.apply_damage_to_next_model(3)  # kills model 1 (2), spills 1 onto model 2
	assert_eq(leftover, 0)
	assert_eq(unit.model_wounds_remaining, [1, 2])
	assert_eq(unit.models_alive, 2)
	assert_eq(unit.models_lost_this_turn, 1)


func test_apply_damage_exceeding_total_wounds_returns_leftover_and_destroys_unit() -> void:
	var unit := UnitInstance.new(_make_stats(2, 2), 0)
	var leftover := unit.apply_damage_to_next_model(10)
	assert_eq(leftover, 6)  # 10 - (2 + 2)
	assert_eq(unit.models_alive, 0)
	assert_true(unit.is_destroyed)
	assert_eq(unit.models_lost_this_turn, 2)


func test_remove_one_model_reduces_count_and_destroys_when_empty() -> void:
	var unit := UnitInstance.new(_make_stats(1, 1), 0)
	unit.remove_one_model()
	assert_eq(unit.models_alive, 0)
	assert_true(unit.is_destroyed)


func test_remaining_move_inches_matches_stats() -> void:
	var unit := UnitInstance.new(_make_stats(), 0)
	assert_eq(unit.remaining_move_inches(), 5.0)


func test_reset_turn_flags_clears_all_flags() -> void:
	var unit := UnitInstance.new(_make_stats(), 0)
	unit.has_moved = true
	unit.has_run_or_advanced = true
	unit.has_charged = true
	unit.has_fallen_back = true
	unit.has_shot = true
	unit.models_lost_this_turn = 2
	unit.battleshock_failed_this_turn = true

	unit.reset_turn_flags()

	assert_false(unit.has_moved)
	assert_false(unit.has_run_or_advanced)
	assert_false(unit.has_charged)
	assert_false(unit.has_fallen_back)
	assert_false(unit.has_shot)
	assert_eq(unit.models_lost_this_turn, 0)
	assert_false(unit.battleshock_failed_this_turn)


func test_match_state_filters_by_owner_and_alive() -> void:
	var state := MatchState.new()
	var p0_alive := UnitInstance.new(_make_stats(), 0)
	var p0_dead := UnitInstance.new(_make_stats(), 0)
	p0_dead.is_destroyed = true
	var p1_alive := UnitInstance.new(_make_stats(), 1)
	state.units = [p0_alive, p0_dead, p1_alive]

	assert_eq(state.units_for_player(0), [p0_alive])
	assert_eq(state.enemy_units_of(p0_alive), [p1_alive])
