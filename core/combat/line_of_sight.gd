## Pure Vector2/Rect2 geometry, no scene tree dependency. Units are still
## single points (see UnitInstance/is_in_engagement_range), so LoS is
## "does the segment between the two unit positions cross any
## blocks_line_of_sight terrain footprint" rather than true model-to-model
## LoS. provides_cover is intentionally not read here — a faithful partial-
## cover approximation isn't meaningful yet while units are single points.
class_name LineOfSight
extends RefCounted


static func is_blocked(from: Vector2, to: Vector2, terrain: Array[TerrainPiece]) -> bool:
	for piece in terrain:
		if piece.blocks_line_of_sight and _segment_intersects_rect(from, to, piece.footprint_inches):
			return true
	return false


static func _segment_intersects_rect(a: Vector2, b: Vector2, rect: Rect2) -> bool:
	if rect.has_point(a) or rect.has_point(b):
		return true

	var corners: Array[Vector2] = [
		rect.position,
		rect.position + Vector2(rect.size.x, 0),
		rect.position + rect.size,
		rect.position + Vector2(0, rect.size.y),
	]
	for i in 4:
		var p1: Vector2 = corners[i]
		var p2: Vector2 = corners[(i + 1) % 4]
		if Geometry2D.segment_intersects_segment(a, b, p1, p2) != null:
			return true
	return false
