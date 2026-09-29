## Ruler shown while a unit token is being dragged during the Movement Phase:
## a line from where the unit currently stands to the cursor, labelled
## "distance / max Move". Purely visual — main.gd feeds it the numbers and the
## can_move_to verdict; it never touches game state.
class_name DragRuler
extends Node2D

var _active: bool = false
var _start_px: Vector2 = Vector2.ZERO
var _end_px: Vector2 = Vector2.ZERO
var _max_inches: float = 0.0
var _valid: bool = false


func show_drag(start_inches: Vector2, end_inches: Vector2, max_inches: float, valid: bool) -> void:
	_active = true
	_start_px = start_inches * BoardScale.PIXELS_PER_INCH
	_end_px = end_inches * BoardScale.PIXELS_PER_INCH
	_max_inches = max_inches
	_valid = valid
	queue_redraw()


func hide_drag() -> void:
	_active = false
	queue_redraw()


func _draw() -> void:
	if not _active:
		return
	var color := Color(0.4, 1.0, 0.4) if _valid else Color(1.0, 0.4, 0.4)
	draw_line(_start_px, _end_px, color, 2.0)
	var inches: float = BoardScale.px_to_inches(_start_px.distance_to(_end_px))
	draw_string(
		ThemeDB.fallback_font, _end_px + Vector2(12, -12),
		"%.1f\" / %.1f\"" % [inches, _max_inches], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color
	)
