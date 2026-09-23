## Shared Charge/Combat/Fight-phase logic: activation order and pile-in.
##
## Scope note: units are still single points with a model count (see
## UnitInstance/is_in_engagement_range) — no per-model positions exist yet,
## so "real" per-model pile-in has no geometric meaning. Pile-in here is a
## whole-unit nudge of up to PILE_IN_INCHES toward the target, reusing
## MovementMath so it obeys the same terrain-block rule as normal movement.
## AoSFightPhase/FortyKFightPhase only override get_phase_name() for now —
## the two editions' fight-order/pile-in text mostly agrees at this scope.
class_name FightPhaseBase
extends GamePhase

const PILE_IN_INCHES: float = 3.0

var _activation_queue: Array[UnitInstance] = []


func on_enter() -> void:
	_activation_queue = _build_activation_order()


## Pops and returns the next unit to activate, or null once the queue is
## empty (all engaged units have fought this phase).
func next_to_fight() -> UnitInstance:
	return _activation_queue.pop_front() if not _activation_queue.is_empty() else null


func activation_queue() -> Array[UnitInstance]:
	return _activation_queue


## Nudges `unit` up to PILE_IN_INCHES directly toward `target_enemy`,
## stopping short if that's closer than the full pile-in distance. Blocked
## by impassable terrain like any other move.
func declare_pile_in(unit: UnitInstance, target_enemy: UnitInstance) -> Dictionary:
	var to_target: Vector2 = target_enemy.position_inches - unit.position_inches
	var distance: float = to_target.length()
	if distance <= 0.0:
		return {"ok": true, "reason": ""}

	var move_distance: float = minf(PILE_IN_INCHES, distance)
	var destination: Vector2 = unit.position_inches + to_target.normalized() * move_distance

	var check := MovementMath.validate_move(unit.position_inches, destination, PILE_IN_INCHES, turn_manager.match_state.terrain)
	if check.ok:
		unit.position_inches = destination
	return check


func can_fight(attacker: UnitInstance, target: UnitInstance) -> Dictionary:
	if attacker.has_fought:
		return {"ok": false, "reason": "already_fought"}
	var range_inches: float = turn_manager.ruleset.get_engagement_range_inches()
	if attacker.position_inches.distance_to(target.position_inches) > range_inches:
		return {"ok": false, "reason": "out_of_engagement_range"}
	return {"ok": true, "reason": ""}


func declare_fight(attacker: UnitInstance, weapon: WeaponProfile, target: UnitInstance, resolver: AttackResolver) -> Dictionary:
	var check := can_fight(attacker, target)
	if not check.ok:
		return {"ok": false, "reason": check.reason, "outcome": null}

	attacker.has_fought = true
	var outcome: AttackOutcome = resolver.resolve_attack(attacker, weapon, target, {})
	return {"ok": true, "reason": "", "outcome": outcome}


## Charging units fight first (both editions grant the charger priority),
## then remaining engaged units alternate by player, starting with whoever
## is not the active player this turn (a placeholder tie-break — real
## battle-round priority isn't modeled yet).
func _build_activation_order() -> Array[UnitInstance]:
	var engaged: Array[UnitInstance] = []
	for unit in turn_manager.match_state.units:
		if not unit.is_destroyed and turn_manager.ruleset.is_in_engagement_range(unit, turn_manager.match_state.units):
			engaged.append(unit)

	var chargers: Array[UnitInstance] = engaged.filter(func(u: UnitInstance): return u.has_charged)
	var others: Array[UnitInstance] = engaged.filter(func(u: UnitInstance): return not u.has_charged)

	var by_player: Dictionary = {0: [], 1: []}
	for unit in others:
		by_player[unit.owner_player].append(unit)

	var turn_order: Array[int] = [1 - turn_manager.active_player, turn_manager.active_player]
	var interleaved: Array[UnitInstance] = []
	var i := 0
	while not by_player[0].is_empty() or not by_player[1].is_empty():
		var player: int = turn_order[i % 2]
		var queue: Array = by_player[player]
		if not queue.is_empty():
			interleaved.append(queue.pop_front())
		i += 1

	return chargers + interleaved
