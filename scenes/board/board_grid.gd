## Draws a placeholder tabletop outline and a 12"-spaced grid so the board
## has a visible scale reference. Table size defaults to a standard 44"x60"
## table (AoS4/40k both commonly play on this or a 44"x30"/44"x90" variant).
extends Node2D

@export var table_width_inches: float = BoardScale.TABLE_WIDTH_INCHES
@export var table_height_inches: float = BoardScale.TABLE_HEIGHT_INCHES
@export var pixels_per_inch: float = BoardScale.PIXELS_PER_INCH


func _draw() -> void:
	var width: float = table_width_inches * pixels_per_inch
	var height: float = table_height_inches * pixels_per_inch
	var border_color := Color(1, 1, 1, 0.6)
	var grid_color := Color(1, 1, 1, 0.15)
	var step: float = 12.0 * pixels_per_inch

	draw_rect(Rect2(Vector2.ZERO, Vector2(width, height)), border_color, false, 2.0)

	var x: float = step
	while x < width:
		draw_line(Vector2(x, 0), Vector2(x, height), grid_color)
		x += step

	var y: float = step
	while y < height:
		draw_line(Vector2(0, y), Vector2(width, y), grid_color)
		y += step
