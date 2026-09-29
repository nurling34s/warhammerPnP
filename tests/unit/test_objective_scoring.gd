extends GutTest


func _make_unit(player: int, position: Vector2, control: int = 1) -> UnitInstance:
	var stats := AoSUnitStats.new()
	stats.control_score = control
	var unit := UnitInstance.new(stats, player)
	unit.position_inches = position
	return unit


## Ported to 40k in Phase 5f: ObjectiveScoring now reads
## FortyKUnitStats.objective_control the same way it reads
## AoSUnitStats.control_score.
func _make_forty_k_unit(player: int, position: Vector2, control: int = 1) -> UnitInstance:
	var stats := FortyKUnitStats.new()
	stats.objective_control = control
	var unit := UnitInstance.new(stats, player)
	unit.position_inches = position
	return unit


func _make_objective(position: Vector2, radius: float = 6.0) -> ObjectiveMarker:
	var objective := ObjectiveMarker.new()
	objective.position_inches = position
	objective.radius_inches = radius
	return objective


func test_lone_unit_within_radius_controls_and_scores_a_point() -> void:
	var match_state := MatchState.new()
	var unit := _make_unit(0, Vector2(1, 0))
	match_state.units.append(unit)
	var objective := _make_objective(Vector2(0, 0))
	match_state.objectives.append(objective)

	ObjectiveScoring.score_objectives(match_state)

	assert_eq(objective.controlled_by, 0)
	assert_eq(match_state.victory_points[0], 1)
	assert_eq(match_state.victory_points[1], 0)


func test_unit_outside_radius_does_not_control() -> void:
	var match_state := MatchState.new()
	var unit := _make_unit(0, Vector2(20, 0))
	match_state.units.append(unit)
	var objective := _make_objective(Vector2(0, 0))
	match_state.objectives.append(objective)

	ObjectiveScoring.score_objectives(match_state)

	assert_eq(objective.controlled_by, -1)
	assert_eq(match_state.victory_points[0], 0)


func test_higher_control_score_wins_contested_objective() -> void:
	var match_state := MatchState.new()
	var weak_unit := _make_unit(0, Vector2(1, 0), 1)
	var strong_unit := _make_unit(1, Vector2(-1, 0), 3)
	match_state.units.append(weak_unit)
	match_state.units.append(strong_unit)
	var objective := _make_objective(Vector2(0, 0))
	match_state.objectives.append(objective)

	ObjectiveScoring.score_objectives(match_state)

	assert_eq(objective.controlled_by, 1)
	assert_eq(match_state.victory_points[1], 1)
	assert_eq(match_state.victory_points[0], 0)


func test_tied_control_score_leaves_objective_uncontrolled() -> void:
	var match_state := MatchState.new()
	var unit_a := _make_unit(0, Vector2(1, 0), 2)
	var unit_b := _make_unit(1, Vector2(-1, 0), 2)
	match_state.units.append(unit_a)
	match_state.units.append(unit_b)
	var objective := _make_objective(Vector2(0, 0))
	match_state.objectives.append(objective)

	ObjectiveScoring.score_objectives(match_state)

	assert_eq(objective.controlled_by, -1)
	assert_eq(match_state.victory_points[0], 0)
	assert_eq(match_state.victory_points[1], 0)


func test_destroyed_unit_does_not_contribute_control() -> void:
	var match_state := MatchState.new()
	var unit := _make_unit(0, Vector2(1, 0))
	unit.is_destroyed = true
	match_state.units.append(unit)
	var objective := _make_objective(Vector2(0, 0))
	match_state.objectives.append(objective)

	ObjectiveScoring.score_objectives(match_state)

	assert_eq(objective.controlled_by, -1)


func test_scoring_accumulates_across_multiple_calls() -> void:
	var match_state := MatchState.new()
	var unit := _make_unit(0, Vector2(1, 0))
	match_state.units.append(unit)
	var objective := _make_objective(Vector2(0, 0))
	match_state.objectives.append(objective)

	ObjectiveScoring.score_objectives(match_state)
	ObjectiveScoring.score_objectives(match_state)

	assert_eq(match_state.victory_points[0], 2)


func test_forty_k_unit_controls_via_objective_control_stat() -> void:
	var match_state := MatchState.new()
	var unit := _make_forty_k_unit(0, Vector2(1, 0), 2)
	match_state.units.append(unit)
	var objective := _make_objective(Vector2(0, 0))
	match_state.objectives.append(objective)

	ObjectiveScoring.score_objectives(match_state)

	assert_eq(objective.controlled_by, 0)
	assert_eq(match_state.victory_points[0], 1)


func test_aos_and_forty_k_units_can_contest_the_same_objective() -> void:
	var match_state := MatchState.new()
	var aos_unit := _make_unit(0, Vector2(1, 0), 1)
	var forty_k_unit := _make_forty_k_unit(1, Vector2(-1, 0), 3)
	match_state.units.append(aos_unit)
	match_state.units.append(forty_k_unit)
	var objective := _make_objective(Vector2(0, 0))
	match_state.objectives.append(objective)

	ObjectiveScoring.score_objectives(match_state)

	assert_eq(objective.controlled_by, 1)
	assert_eq(match_state.victory_points[1], 1)
