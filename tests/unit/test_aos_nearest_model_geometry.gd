## Confirms AoS4's phase overrides actually use nearest-model geometry
## (UnitInstance.model_positions), not just the unit's anchor point — the
## point of Phase 5a. Single-model units (models_per_unit == 1, the default
## used by most other tests) can't distinguish the two, so these use
## multi-model units explicitly.
extends GutTest


func _make_unit(player: int, position: Vector2, models: int) -> UnitInstance:
	var stats := AoSUnitStats.new()
	stats.models_per_unit = models
	stats.health_per_model = 1
	var unit := UnitInstance.new(stats, player)
	unit.position_inches = position
	return unit


func test_check_unit_coherency_is_true_for_the_auto_generated_formation() -> void:
	var ruleset := AoSRuleset.new()
	var unit := _make_unit(0, Vector2.ZERO, 5)
	assert_true(ruleset.check_unit_coherency(unit))


func test_multi_model_units_can_be_engaged_even_when_anchors_are_far_apart() -> void:
	var ruleset := AoSRuleset.new()
	# 3x3 formations (anchor at top-left corner, 1" spacing) are ~2.8" across
	# their diagonal, so two 3-model-wide units with anchors 4" apart can
	# still have their nearest models within AoS4's 3" engagement range even
	# though the anchors themselves are not.
	var a := _make_unit(0, Vector2(0, 0), 9)
	var b := _make_unit(1, Vector2(4, 0), 9)

	assert_true(a.position_inches.distance_to(b.position_inches) > ruleset.get_engagement_range_inches())
	assert_true(ruleset.is_in_engagement_range(a, [a, b]))


func test_pile_in_aims_at_the_enemys_nearest_model_not_its_anchor() -> void:
	var ruleset := AoSRuleset.new()
	var tm := TurnManager.new(ruleset)
	var phase := AoSFightPhase.new(tm)

	var mover := _make_unit(0, Vector2(0, 0), 1)
	# 3x3 formation at x 2..4, y -4..-2: nearest model (2, -2) is ~2.83" away,
	# inside AoS4's 3", while the anchor (2, -4) is ~4.47" away.
	var target := _make_unit(1, Vector2(2, -4), 9)

	var aim: Vector2 = target.nearest_model_point_to(mover)
	assert_eq(aim, Vector2(2, -2))

	var result := phase.declare_pile_in(mover, target)

	assert_true(result.ok)
	assert_almost_eq(mover.nearest_model_distance_to(target), MovementMath.CONTACT_GAP_INCHES, 0.001)
	assert_true(mover.position_inches.x > 0.0 and mover.position_inches.y < 0.0, "moved toward the nearest model")
