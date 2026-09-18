extends GutTest


func _make_zones() -> Array[DeploymentZone]:
	var zone0 := DeploymentZone.new()
	zone0.owner_player = 0
	zone0.rect_inches = Rect2(0, 0, 10, 44)

	var zone1 := DeploymentZone.new()
	zone1.owner_player = 1
	zone1.rect_inches = Rect2(50, 0, 10, 44)

	var zones: Array[DeploymentZone] = [zone0, zone1]
	return zones


func _make_unit(player: int) -> UnitInstance:
	var stats := AoSUnitStats.new()
	stats.models_per_unit = 1
	return UnitInstance.new(stats, player)


func test_can_place_inside_own_zone() -> void:
	var manager := DeploymentManager.new(_make_zones(), MatchState.new())
	var unit := _make_unit(0)
	assert_true(manager.can_place(unit, Vector2(5, 5)))


func test_cannot_place_outside_own_zone() -> void:
	var manager := DeploymentManager.new(_make_zones(), MatchState.new())
	var unit := _make_unit(0)
	assert_false(manager.can_place(unit, Vector2(55, 5)), "player 0's zone does not cover x=55")


func test_cannot_place_in_enemy_zone() -> void:
	var manager := DeploymentManager.new(_make_zones(), MatchState.new())
	var unit := _make_unit(1)
	assert_false(manager.can_place(unit, Vector2(5, 5)), "player 1 cannot deploy in player 0's zone")


func test_place_unit_adds_to_match_state_and_marks_deployed() -> void:
	var state := MatchState.new()
	var manager := DeploymentManager.new(_make_zones(), state)
	var unit := _make_unit(0)

	var placed := manager.place_unit(unit, Vector2(5, 5))

	assert_true(placed)
	assert_true(unit.has_deployed)
	assert_eq(unit.position_inches, Vector2(5, 5))
	assert_true(state.units.has(unit))


func test_place_unit_fails_and_does_not_mutate_when_illegal() -> void:
	var manager := DeploymentManager.new(_make_zones(), MatchState.new())
	var unit := _make_unit(0)

	var placed := manager.place_unit(unit, Vector2(55, 5))

	assert_false(placed)
	assert_false(unit.has_deployed)


func test_deployment_complete_fires_only_once_all_units_placed() -> void:
	var manager := DeploymentManager.new(_make_zones(), MatchState.new(), [_make_unit(0), _make_unit(1)])
	# A one-element Array, not a plain int: GDScript lambdas capture local
	# value-type variables (int) by value, so `complete_count += 1` inside
	# the closure would mutate an independent copy. Array is captured by
	# reference (it's a ref-counted container), so mutating its contents
	# is visible outside the closure.
	var complete_count := [0]
	manager.deployment_complete.connect(func(): complete_count[0] += 1)

	manager.place_unit(manager.pending_units[0], Vector2(5, 5))
	assert_eq(complete_count[0], 0, "should not fire until every pending unit is placed")

	manager.place_unit(manager.pending_units[0], Vector2(55, 5))
	assert_eq(complete_count[0], 1)


func test_current_deploying_player_alternates_after_each_placement() -> void:
	var manager := DeploymentManager.new(_make_zones(), MatchState.new(), [_make_unit(0), _make_unit(1)])
	assert_eq(manager.current_deploying_player, 0)

	manager.place_unit(manager.pending_units[0], Vector2(5, 5))
	assert_eq(manager.current_deploying_player, 1)
