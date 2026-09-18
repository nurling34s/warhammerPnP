## Age of Sigmar 4th-edition ruleset. Phase order per turn: Hero, Movement,
## Shooting, Charge, Combat, End (Battleshock resolves inside End Phase for
## both players, per AoS4 — it is not a separate phase, unlike AoS3).
##
## Only phase sequencing is implemented so far; combat math, charge rolls,
## battleshock and coherency are Phase 2/3 work (see RulesetProvider).
class_name AoSRuleset
extends RulesetProvider


func get_id() -> StringName:
	return &"aos4"


func build_phase_sequence(turn_manager: TurnManager) -> Array[GamePhase]:
	var names: Array[StringName] = [
		&"Hero Phase",
		&"Movement Phase",
		&"Shooting Phase",
		&"Charge Phase",
		&"Combat Phase",
		&"End Phase",
	]
	var phases: Array[GamePhase] = []
	for phase_name in names:
		phases.append(NamedPlaceholderPhase.new(turn_manager, phase_name))
	return phases


func get_unit_stats_script() -> Script:
	return AoSUnitStats
