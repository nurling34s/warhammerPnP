extends GutTest


func _make_unit(player: int, position: Vector2, stats: UnitStats) -> UnitInstance:
	var unit := UnitInstance.new(stats, player)
	unit.position_inches = position
	return unit


func test_aos_engagement_range_is_3_inches() -> void:
	var ruleset := AoSRuleset.new()
	assert_eq(ruleset.get_engagement_range_inches(), 3.0)


func test_forty_k_engagement_range_is_1_inch() -> void:
	var ruleset := FortyKRuleset.new()
	assert_eq(ruleset.get_engagement_range_inches(), 1.0)


func test_aos_unit_just_inside_engagement_range_is_engaged() -> void:
	var ruleset := AoSRuleset.new()
	var stats := AoSUnitStats.new()
	var mover := _make_unit(0, Vector2(0, 0), stats)
	var enemy := _make_unit(1, Vector2(2.9, 0), stats)
	assert_true(ruleset.is_in_engagement_range(mover, [mover, enemy]))


func test_aos_unit_just_outside_engagement_range_is_not_engaged() -> void:
	var ruleset := AoSRuleset.new()
	var stats := AoSUnitStats.new()
	var mover := _make_unit(0, Vector2(0, 0), stats)
	var enemy := _make_unit(1, Vector2(3.1, 0), stats)
	assert_false(ruleset.is_in_engagement_range(mover, [mover, enemy]))


func test_forty_k_unit_just_inside_engagement_range_is_engaged() -> void:
	var ruleset := FortyKRuleset.new()
	var stats := FortyKUnitStats.new()
	var mover := _make_unit(0, Vector2(0, 0), stats)
	var enemy := _make_unit(1, Vector2(0.9, 0), stats)
	assert_true(ruleset.is_in_engagement_range(mover, [mover, enemy]))


func test_forty_k_unit_just_outside_engagement_range_is_not_engaged() -> void:
	var ruleset := FortyKRuleset.new()
	var stats := FortyKUnitStats.new()
	var mover := _make_unit(0, Vector2(0, 0), stats)
	var enemy := _make_unit(1, Vector2(1.1, 0), stats)
	assert_false(ruleset.is_in_engagement_range(mover, [mover, enemy]))


func test_friendly_units_never_count_as_engaged() -> void:
	var ruleset := AoSRuleset.new()
	var stats := AoSUnitStats.new()
	var mover := _make_unit(0, Vector2(0, 0), stats)
	var friend := _make_unit(0, Vector2(0.1, 0), stats)
	assert_false(ruleset.is_in_engagement_range(mover, [mover, friend]))


func test_destroyed_enemy_units_do_not_count_as_engaged() -> void:
	var ruleset := AoSRuleset.new()
	var stats := AoSUnitStats.new()
	var mover := _make_unit(0, Vector2(0, 0), stats)
	var enemy := _make_unit(1, Vector2(0.1, 0), stats)
	enemy.is_destroyed = true
	assert_false(ruleset.is_in_engagement_range(mover, [mover, enemy]))
