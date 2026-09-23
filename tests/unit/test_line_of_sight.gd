extends GutTest


func _make_blocker(rect: Rect2) -> TerrainPiece:
	var piece := TerrainPiece.new()
	piece.footprint_inches = rect
	piece.blocks_line_of_sight = true
	return piece


func test_segment_crossing_blocker_is_blocked() -> void:
	var blocker := _make_blocker(Rect2(4, 4, 4, 4))  # covers x:[4,8] y:[4,8]
	var terrain: Array[TerrainPiece] = [blocker]
	assert_true(LineOfSight.is_blocked(Vector2(0, 6), Vector2(12, 6), terrain))


func test_segment_missing_blocker_is_not_blocked() -> void:
	var blocker := _make_blocker(Rect2(4, 4, 4, 4))
	var terrain: Array[TerrainPiece] = [blocker]
	assert_false(LineOfSight.is_blocked(Vector2(0, 20), Vector2(12, 20), terrain))


func test_endpoint_inside_blocker_counts_as_blocked() -> void:
	var blocker := _make_blocker(Rect2(4, 4, 4, 4))
	var terrain: Array[TerrainPiece] = [blocker]
	assert_true(LineOfSight.is_blocked(Vector2(6, 6), Vector2(20, 6), terrain))


func test_terrain_that_does_not_block_los_is_ignored() -> void:
	var piece := TerrainPiece.new()
	piece.footprint_inches = Rect2(4, 4, 4, 4)
	piece.blocks_line_of_sight = false
	var terrain: Array[TerrainPiece] = [piece]
	assert_false(LineOfSight.is_blocked(Vector2(0, 6), Vector2(12, 6), terrain))


func test_no_terrain_is_never_blocked() -> void:
	assert_false(LineOfSight.is_blocked(Vector2(0, 0), Vector2(10, 10), []))
