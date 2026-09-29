## Shared Charge Phase logic: declare a charge against an enemy unit, roll the
## ruleset's charge distance, and — if the roll is long enough to reach
## engagement range — move the whole (rigid) formation toward the target.
## Uses nearest-model geometry directly since both rulesets share it now
## (Phase 5f); AoSChargePhase/FortyKChargePhase are thin subclasses ready for
## divergence. The whole (rigid) formation moves along the line between the
## two nearest models, until the bases touch (MovementMath.CONTACT_GAP_INCHES).
## Distances are edge-to-edge (UnitInstance.nearest_edge_distance_to).
class_name ChargePhaseBase
extends GamePhase


func get_phase_name() -> StringName:
	return &"Charge Phase"


## Pure check — does not mutate anything. Returns {"ok": bool, "reason": String}.
func can_declare_charge(unit: UnitInstance, target: UnitInstance, all_units: Array) -> Dictionary:
	if target.is_destroyed or target.owner_player == unit.owner_player:
		return {"ok": false, "reason": "invalid_target"}
	if unit.has_attempted_charge:
		return {"ok": false, "reason": "already_attempted_charge"}
	if unit.has_fallen_back:
		return {"ok": false, "reason": "cannot_charge_after_falling_back"}
	if turn_manager.ruleset.is_in_engagement_range(unit, all_units):
		return {"ok": false, "reason": "already_engaged"}
	return {"ok": true, "reason": ""}


## Rolls the charge distance and resolves the charge. A unit only gets one
## attempt per phase, so has_attempted_charge is set whether or not the roll
## succeeds; has_charged (which grants fight-first priority) only on success.
## Returns {"ok": bool, "reason": String, "distance_rolled": int}.
func declare_charge(unit: UnitInstance, target: UnitInstance, all_units: Array, dice: DiceRoller) -> Dictionary:
	var check := can_declare_charge(unit, target, all_units)
	if not check.ok:
		return {"ok": false, "reason": check.reason, "distance_rolled": 0, "distance_needed": 0.0}

	unit.has_attempted_charge = true
	var range_inches: float = turn_manager.ruleset.get_engagement_range_inches()
	var distance_needed: float = maxf(0.0, unit.nearest_edge_distance_to(target) - range_inches)
	var distance_rolled: int = turn_manager.ruleset.roll_charge_distance(unit, dice)

	if float(distance_rolled) < distance_needed:
		return {"ok": false, "reason": "failed_charge_roll", "distance_rolled": distance_rolled, "distance_needed": distance_needed}

	var nearest_distance: float = unit.nearest_edge_distance_to(target)
	var to_aim: Vector2 = target.nearest_model_point_to(unit) - unit.nearest_model_point_to(target)
	var move_distance: float = minf(float(distance_rolled), maxf(0.0, nearest_distance - MovementMath.CONTACT_GAP_INCHES))
	if move_distance > 0.0 and to_aim.length() > 0.0:
		var destination: Vector2 = unit.position_inches + to_aim.normalized() * move_distance
		var move_check := MovementMath.validate_move(unit.position_inches, destination, float(distance_rolled), turn_manager.match_state.terrain)
		if not move_check.ok:
			return {"ok": false, "reason": move_check.reason, "distance_rolled": distance_rolled, "distance_needed": distance_needed}
		unit.position_inches = destination

	unit.has_charged = true
	return {"ok": true, "reason": "", "distance_rolled": distance_rolled, "distance_needed": distance_needed}
