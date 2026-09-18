## Click-drag ruler available in any phase, independent of the movement
## system — real players constantly pre-measure charges/aura ranges, not
## just during their own Movement Phase. Uses the right mouse button so it
## never competes with left-click deployment placement or unit dragging.
extends Node2D

var _dragging: bool = false
var _start_px: Vector2 = Vector2.ZERO
var _current_px: Vector2 = Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			_dragging = true
			_start_px = get_global_mouse_position()
			_current_px = _start_px
		else:
			_dragging = false
		queue_redraw()
	elif event is InputEventMouseMotion and _dragging:
		_current_px = get_global_mouse_position()
		queue_redraw()


func _draw() -> void:
	if not _dragging:
		return
	draw_line(_start_px, _current_px, Color(1, 1, 0, 0.9), 2.0)
	var inches: float = BoardScale.px_to_inches(_start_px.distance_to(_current_px))
	draw_string(
		ThemeDB.fallback_font, _current_px + Vector2(10, -10),
		"%.1f\"" % inches, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 0)
	)
