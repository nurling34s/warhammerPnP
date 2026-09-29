## Shared Fight-phase logic: activation order, pile-in and declaring a fight.
##
## Activation is modelled dynamically rather than as a pre-built queue: the
## engaged, not-yet-fought units of both players are "pending", and
## eligible_units() says which of them may activate right now — see
## _chargers_fight_first() and _first_activating_player() for the per-edition
## differences (AoSFightPhase / FortyKFightPhase override them).
##
## Pile-in is a rigid nudge of the whole unit along the line between the two
## nearest models, up to PILE_IN_INCHES, until the bases touch
## (MovementMath.CONTACT_GAP_INCHES, edge-to-edge). It only happens for a unit that is already in engagement
## range of the target; reuses MovementMath's terrain-block rule.
class_name FightPhaseBase
extends GamePhase

const PILE_IN_INCHES: float = 3.0

## The player whose unit activates next among units without priority.
var _next_player: int = 0


func on_enter() -> void:
	# Flags of the player who is NOT taking this turn are stale from their own
	# last turn, and both players fight in every Fight phase.
	for unit in turn_manager.match_state.units:
		unit.has_fought = false
	_next_player = _first_activating_player()


## True if the active player's charging units must all fight before anyone else.
func _chargers_fight_first() -> bool:
	return false


## Which player picks the first non-priority unit.
func _first_activating_player() -> int:
	return turn_manager.active_player


## Living, not-yet-fought units in engagement range of an enemy, both players.
func pending_units() -> Array[UnitInstance]:
	var pending: Array[UnitInstance] = []
	for unit in turn_manager.match_state.units:
		if unit.is_destroyed or unit.has_fought:
			continue
		if turn_manager.ruleset.is_in_engagement_range(unit, turn_manager.match_state.units):
			pending.append(unit)
	return pending


## The pending units that may activate right now.
func eligible_units() -> Array[UnitInstance]:
	var pending := pending_units()

	if _chargers_fight_first():
		var chargers: Array[UnitInstance] = pending.filter(
			func(u: UnitInstance): return u.has_charged and u.owner_player == turn_manager.active_player
		)
		if not chargers.is_empty():
			return chargers

	var mine: Array[UnitInstance] = pending.filter(func(u: UnitInstance): return u.owner_player == _next_player)
	return mine if not mine.is_empty() else pending


## Nudges `unit` toward `target_enemy` (see class doc). Refused with
## "not_engaged" unless the unit is already in engagement range of the target.
func declare_pile_in(unit: UnitInstance, target_enemy: UnitInstance) -> Dictionary:
	var range_inches: float = turn_manager.ruleset.get_engagement_range_inches()
	if _engagement_distance(unit, target_enemy) > range_inches:
		return {"ok": false, "reason": "not_engaged"}

	var nearest_distance: float = unit.nearest_edge_distance_to(target_enemy)
	var to_aim: Vector2 = target_enemy.nearest_model_point_to(unit) - unit.nearest_model_point_to(target_enemy)
	var move_distance: float = minf(PILE_IN_INCHES, maxf(0.0, nearest_distance - MovementMath.CONTACT_GAP_INCHES))
	if move_distance <= 0.0 or to_aim.length() <= 0.0:
		return {"ok": true, "reason": ""}

	var destination: Vector2 = unit.position_inches + to_aim.normalized() * move_distance
	var check := MovementMath.validate_move(unit.position_inches, destination, PILE_IN_INCHES, turn_manager.match_state.terrain)
	if check.ok:
		unit.position_inches = destination
	return check


func can_fight(attacker: UnitInstance, target: UnitInstance) -> Dictionary:
	if attacker.has_fought:
		return {"ok": false, "reason": "already_fought"}
	var range_inches: float = turn_manager.ruleset.get_engagement_range_inches()
	if _engagement_distance(attacker, target) > range_inches:
		return {"ok": false, "reason": "out_of_engagement_range"}
	if not eligible_units().has(attacker):
		return {"ok": false, "reason": "not_this_units_turn_to_fight"}
	return {"ok": true, "reason": ""}


## Edge-to-edge nearest-model distance, shared by both rulesets.
func _engagement_distance(attacker: UnitInstance, target: UnitInstance) -> float:
	return attacker.nearest_edge_distance_to(target)


func declare_fight(attacker: UnitInstance, weapon: WeaponProfile, target: UnitInstance, resolver: AttackResolver) -> Dictionary:
	var check := can_fight(attacker, target)
	if not check.ok:
		return {"ok": false, "reason": check.reason, "outcome": null}

	attacker.has_fought = true
	_next_player = 1 - attacker.owner_player
	var outcome: AttackOutcome = resolver.resolve_attack(attacker, weapon, target, {})
	return {"ok": true, "reason": "", "outcome": outcome}
