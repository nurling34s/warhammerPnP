## AoS4 End Phase: Battleshock resolves here for BOTH players simultaneously
## (not a separate phase, and not per-player — this is what distinguishes
## AoS4 from the earlier draft plan's "separate Battleshock phase").
## Minimal placeholder consequence on a failed test: remove one additional
## model and flag battleshock_failed_this_turn — no ability-lockout or
## other effects yet (Phase 4 scope).
class_name AoSEndPhase
extends GamePhase


func get_phase_name() -> StringName:
	return &"End Phase"


func on_enter() -> void:
	var dice := DiceRoller.new()
	for unit in turn_manager.match_state.units:
		resolve_battleshock_for_unit(unit, dice)


func resolve_battleshock_for_unit(unit: UnitInstance, dice: DiceRoller) -> void:
	if unit.is_destroyed or unit.models_lost_this_turn <= 0:
		return
	var passed: bool = turn_manager.ruleset.resolve_battleshock(unit, unit.models_lost_this_turn, dice)
	if not passed:
		unit.remove_one_model()
		unit.battleshock_failed_this_turn = true
