## Shared distance + terrain-block check, extracted from MovementPhaseBase
## so FightPhaseBase's pile-in nudge can reuse the exact same validation
## without duplicating it. Pure math, no phase/turn-manager coupling.
class_name MovementMath
extends RefCounted


## Returns {"ok": bool, "reason": String}. Does not check engagement range —
## that's ruleset-specific and stays in the caller (MovementPhaseBase/
## FightPhaseBase each know whether it applies to their situation).
static func validate_move(current_position: Vector2, destination: Vector2, max_distance: float, terrain: Array[TerrainPiece]) -> Dictionary:
	var distance: float = current_position.distance_to(destination)
	if distance > max_distance:
		return {"ok": false, "reason": "exceeds_move"}

	for piece in terrain:
		if piece.blocks_movement and piece.footprint_inches.has_point(destination):
			return {"ok": false, "reason": "blocked_by_terrain"}

	return {"ok": true, "reason": ""}
