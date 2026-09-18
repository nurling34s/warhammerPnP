## Visual placeholder for one TerrainPiece — same spirit as UnitToken's
## marker rect. Rendering only; blocks_movement etc. are read purely from
## core/'s TerrainPiece Resource by movement validation, not from this node.
class_name TerrainPieceView
extends Node2D

var terrain_piece: TerrainPiece


func apply_piece(piece: TerrainPiece) -> void:
	terrain_piece = piece
	queue_redraw()


func _draw() -> void:
	if not terrain_piece:
		return
	var rect_px := Rect2(
		terrain_piece.footprint_inches.position * BoardScale.PIXELS_PER_INCH,
		terrain_piece.footprint_inches.size * BoardScale.PIXELS_PER_INCH
	)
	var color := Color(0.4, 0.3, 0.2, 0.8) if terrain_piece.blocks_movement else Color(0.3, 0.3, 0.3, 0.5)
	draw_rect(rect_px, color, true)
	draw_rect(rect_px, color.lightened(0.3), false, 2.0)
