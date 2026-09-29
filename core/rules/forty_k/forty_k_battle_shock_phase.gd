## 40k 11th ed Battle-shock Phase: resolves only for the active player's
## units (unlike AoS4's simultaneous End Phase check). Minimal placeholder
## consequence on a failed test: remove one additional model and flag
## battleshock_failed_this_turn — no OC/ability-lockout effects yet (Phase
## 4 scope). This is also 40k's last phase of the turn, so — mirroring
## AoSEndPhase — it's where objective control gets scored (Phase 5f).
class_name FortyKBattleShockPhase
extends GamePhase


func get_phase_name() -> StringName:
	return &"Battle-shock Phase"


func on_enter() -> void:
	var dice := DiceRoller.new()
	for unit in turn_manager.match_state.units_for_player(turn_manager.active_player):
		resolve_battleshock_for_unit(unit, dice)
	ObjectiveScoring.score_objectives(turn_manager.match_state)


func resolve_battleshock_for_unit(unit: UnitInstance, dice: DiceRoller) -> void:
	if unit.is_destroyed or unit.models_lost_this_turn <= 0:
		return
	var passed: bool = turn_manager.ruleset.resolve_battleshock(unit, unit.models_lost_this_turn, dice)
	if not passed:
		unit.remove_one_model()
		unit.battleshock_failed_this_turn = true
