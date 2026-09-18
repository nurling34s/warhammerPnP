extends GutTest


func test_inches_to_px_round_trip() -> void:
	var inches := 12.5
	var px := BoardScale.inches_to_px(inches)
	assert_almost_eq(BoardScale.px_to_inches(px), inches, 0.0001)


func test_pixels_per_inch_matches_grid_default() -> void:
	assert_eq(BoardScale.inches_to_px(1.0), BoardScale.PIXELS_PER_INCH)
