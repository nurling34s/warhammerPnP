## Shared Movement Phase logic: distance validation and engagement-range
## checks. AoSMovementPhase/FortyKMovementPhase override only what actually
## diverges (Fall Back, run/advance) — see _allows_leaving_engagement().
class_name MovementPhaseBase
extends GamePhase


func get_phase_name() -> StringName:
	return &"Movement Phase"


func on_enter() -> void:
	for unit in turn_manager.match_state.units_for_player(turn_manager.active_player):
		unit.reset_turn_flags()


## Pure check — does not mutate anything. Returns {"ok": bool, "reason": String}.
func can_move_to(unit: UnitInstance, destination_inches: Vector2, all_units: Array) -> Dictionary:
	var distance: float = unit.position_inches.distance_to(destination_inches)
	if distance > unit.remaining_move_inches():
		return {"ok": false, "reason": "exceeds_move"}

	if turn_manager.ruleset.is_in_engagement_range(unit, all_units) and not _allows_leaving_engagement(unit):
		return {"ok": false, "reason": "engaged_must_fall_back"}

	for piece in turn_manager.match_state.terrain:
		if piece.blocks_movement and piece.footprint_inches.has_point(destination_inches):
			return {"ok": false, "reason": "blocked_by_terrain"}

	return {"ok": true, "reason": ""}


## Validates and, on success, mutates unit.position_inches/has_moved.
func try_move_unit(unit: UnitInstance, destination_inches: Vector2, all_units: Array) -> Dictionary:
	var result := can_move_to(unit, destination_inches, all_units)
	if result.ok:
		unit.position_inches = destination_inches
		unit.has_moved = true
	return result


## Declares a unit is Falling Back, letting it leave engagement range this
## Movement Phase. Forfeiting later shooting/charging for the turn is a
## Phase 3 concern (those phases don't exist yet) — this only unblocks the
## movement-distance check itself.
func declare_fall_back(unit: UnitInstance) -> void:
	unit.has_fallen_back = true


func _allows_leaving_engagement(unit: UnitInstance) -> bool:
	return unit.has_fallen_back
