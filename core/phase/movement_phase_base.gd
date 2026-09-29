## Shared Movement Phase logic: distance validation and engagement-range
## checks. Both AoS4 and 40k 11th ed forbid voluntarily moving into engagement
## range without charging — only a Charge (not modeled as a real phase yet)
## may close that gap — so that check lives here rather than duplicated per
## ruleset (it used to be AoS-only; ported to 40k in Phase 5f once confirmed
## the two editions agree). AoSMovementPhase/FortyKMovementPhase override only
## what actually diverges (AoS4's Fall Back self-damage) — see
## _allows_leaving_engagement().
class_name MovementPhaseBase
extends GamePhase


func get_phase_name() -> StringName:
	return &"Movement Phase"


func on_enter() -> void:
	for unit in turn_manager.match_state.units_for_player(turn_manager.active_player):
		unit.reset_turn_flags()


## Pure check — does not mutate anything. Returns {"ok": bool, "reason": String}.
func can_move_to(unit: UnitInstance, destination_inches: Vector2, all_units: Array) -> Dictionary:
	if unit.has_moved:
		return {"ok": false, "reason": "already_moved"}

	var basic := MovementMath.validate_move(
		unit.position_inches, destination_inches, unit.remaining_move_inches(), turn_manager.match_state.terrain
	)
	if not basic.ok:
		return basic

	if turn_manager.ruleset.is_in_engagement_range(unit, all_units) and not _allows_leaving_engagement(unit):
		return {"ok": false, "reason": "engaged_must_fall_back"}

	if _would_create_new_engagement(unit, destination_inches, all_units):
		return {"ok": false, "reason": "normal_move_cannot_approach_within_engagement_range"}

	return {"ok": true, "reason": ""}


## True if `unit` is not currently engaged but moving it to `destination`
## would put it in engagement range of an enemy. Checked by temporarily
## moving the unit and reverting — pure from the caller's perspective.
func _would_create_new_engagement(unit: UnitInstance, destination: Vector2, all_units: Array) -> bool:
	if turn_manager.ruleset.is_in_engagement_range(unit, all_units):
		return false  # already engaged; that case is handled by the "must fall back" check above

	var original_position: Vector2 = unit.position_inches
	unit.position_inches = destination
	var now_engaged: bool = turn_manager.ruleset.is_in_engagement_range(unit, all_units)
	unit.position_inches = original_position
	return now_engaged


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
## movement-distance check itself. `dice` is unused here (40k's Fall Back has
## no self-damage) but accepted so AoSMovementPhase's override — which does
## roll self-damage — has a compatible signature.
func declare_fall_back(unit: UnitInstance, _dice: DiceRoller = null) -> void:
	unit.has_fallen_back = true


func _allows_leaving_engagement(unit: UnitInstance) -> bool:
	return unit.has_fallen_back
