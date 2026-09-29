## Visual placeholder for one ObjectiveMarker — same spirit as
## TerrainPieceView. Rendering only; scoring/control is read purely from
## core/'s ObjectiveMarker Resource by ObjectiveScoring, not from this node.
class_name ObjectiveMarkerView
extends Node2D

var objective: ObjectiveMarker

const CONTROL_COLORS := {
	-1: Color(0.7, 0.7, 0.7, 0.6),  # uncontrolled/contested
	0: Color(0.2, 0.5, 0.9, 0.6),   # player 1
	1: Color(0.9, 0.3, 0.2, 0.6),   # player 2
}


func apply_objective(marker: ObjectiveMarker) -> void:
	objective = marker
	queue_redraw()


func _draw() -> void:
	if not objective:
		return
	var center_px: Vector2 = objective.position_inches * BoardScale.PIXELS_PER_INCH
	var radius_px: float = objective.radius_inches * BoardScale.PIXELS_PER_INCH
	var color: Color = CONTROL_COLORS.get(objective.controlled_by, CONTROL_COLORS[-1])
	draw_circle(center_px, radius_px, color)
	draw_arc(center_px, radius_px, 0, TAU, 32, color.lightened(0.4), 2.0)
