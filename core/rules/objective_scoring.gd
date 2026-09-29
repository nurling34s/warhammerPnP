## Pure objective-control scoring, shared by both rulesets since Phase 5f
## (originally AoS4-only — warhammer_age_of_sigmar_4.md section 3.6: objectives
## are scored at end of turn via the Control characteristic; 40k 11th ed's
## Objective Control works the same way at this vertical-slice scope). Called
## from AoSEndPhase.on_enter() and FortyKBattleShockPhase.on_enter() — the
## last phase of each ruleset's turn, standing in for "once per battle round"
## for simplicity (a known, accepted approximation, same as AoS's own).
class_name ObjectiveScoring
extends RefCounted


## For each objective, sums the controlling characteristic (AoSUnitStats.
## control_score or FortyKUnitStats.objective_control) of every non-destroyed
## unit with at least one model within radius_inches, per owning player. The
## strictly-higher total controls it; a tie (including 0-0) leaves it
## uncontrolled. A controlled objective adds one victory point to its
## controller on every call.
static func score_objectives(match_state: MatchState) -> void:
	for objective in match_state.objectives:
		var control_by_player: Dictionary = {}
		for unit in match_state.units:
			if unit.is_destroyed or not _has_model_within(unit, objective):
				continue
			var contribution: int = _control_contribution(unit.stats)
			control_by_player[unit.owner_player] = control_by_player.get(unit.owner_player, 0) + contribution

		objective.controlled_by = _determine_controller(control_by_player)
		if objective.controlled_by >= 0:
			match_state.add_victory_point(objective.controlled_by)


static func _control_contribution(stats: UnitStats) -> int:
	if stats is AoSUnitStats:
		return stats.control_score
	if stats is FortyKUnitStats:
		return stats.objective_control
	return 0


static func _has_model_within(unit: UnitInstance, objective: ObjectiveMarker) -> bool:
	for model_position in unit.model_positions:
		if model_position.distance_to(objective.position_inches) <= objective.radius_inches:
			return true
	return false


static func _determine_controller(control_by_player: Dictionary) -> int:
	var best_player := -1
	var best_score := 0
	var tied := false
	for player in control_by_player:
		var score: int = control_by_player[player]
		if score > best_score:
			best_score = score
			best_player = player
			tied = false
		elif score == best_score and score > 0:
			tied = true
	return -1 if tied else best_player
