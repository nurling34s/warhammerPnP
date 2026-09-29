extends GutTest


func _make_stats(models: int = 4) -> AoSUnitStats:
	var stats := AoSUnitStats.new()
	stats.models_per_unit = models
	stats.health_per_model = 1
	return stats


func test_init_builds_one_model_position_per_model() -> void:
	var unit := UnitInstance.new(_make_stats(4), 0)
	assert_eq(unit.model_positions.size(), 4)


func test_formation_starts_coherent() -> void:
	var unit := UnitInstance.new(_make_stats(5), 0)
	assert_true(unit.is_coherent(UnitInstance.MODEL_SPACING_INCHES))


func test_single_model_unit_is_always_coherent() -> void:
	var unit := UnitInstance.new(_make_stats(1), 0)
	assert_true(unit.is_coherent(UnitInstance.MODEL_SPACING_INCHES))


func test_setting_position_inches_shifts_every_model_by_the_same_delta() -> void:
	var unit := UnitInstance.new(_make_stats(3), 0)
	var offsets_before: Array[Vector2] = []
	for p in unit.model_positions:
		offsets_before.append(p - unit.position_inches)

	unit.position_inches = Vector2(10, -4)

	for i in unit.model_positions.size():
		assert_eq(unit.model_positions[i] - unit.position_inches, offsets_before[i])


func test_apply_damage_that_kills_a_model_removes_its_position_too() -> void:
	var unit := UnitInstance.new(_make_stats(3), 0)
	var second_model_position: Vector2 = unit.model_positions[1]
	unit.apply_damage_to_next_model(1)  # kills model 0 (1 wound each)
	assert_eq(unit.model_positions.size(), 2)
	assert_eq(unit.model_positions[0], second_model_position)


func test_remove_one_model_removes_its_position_too() -> void:
	var unit := UnitInstance.new(_make_stats(2), 0)
	unit.remove_one_model()
	assert_eq(unit.model_positions.size(), 1)


func test_nearest_model_distance_to_is_smaller_than_anchor_distance_when_formations_face_each_other() -> void:
	var a := UnitInstance.new(_make_stats(4), 0)
	var b := UnitInstance.new(_make_stats(4), 1)
	a.position_inches = Vector2(0, 0)
	b.position_inches = Vector2(10, 0)

	var anchor_distance: float = a.position_inches.distance_to(b.position_inches)
	var nearest_distance: float = a.nearest_model_distance_to(b)
	assert_true(nearest_distance < anchor_distance)


func test_nearest_model_point_to_returns_one_of_the_units_own_model_positions() -> void:
	var a := UnitInstance.new(_make_stats(4), 0)
	var b := UnitInstance.new(_make_stats(4), 1)
	b.position_inches = Vector2(10, 0)

	var point: Vector2 = a.nearest_model_point_to(b)
	assert_true(a.model_positions.has(point))
