## Warhammer 40,000 11th-edition ruleset. Phase order per turn: Command,
## Movement, Shooting, Charge, Fight, Battle-shock (exact placement/wording of
## the battle-shock step should be verified against the current core
## rulebook before real army data is entered — see aos_40k.md plan notes).
##
## Only phase sequencing is implemented so far; combat math, charge rolls,
## battle-shock and coherency are Phase 2/3 work (see RulesetProvider).
class_name FortyKRuleset
extends RulesetProvider


func get_id() -> StringName:
	return &"forty_k_11e"


func build_phase_sequence(turn_manager: TurnManager) -> Array[GamePhase]:
	var names: Array[StringName] = [
		&"Command Phase",
		&"Movement Phase",
		&"Shooting Phase",
		&"Charge Phase",
		&"Fight Phase",
		&"Battle-shock Phase",
	]
	var phases: Array[GamePhase] = []
	for phase_name in names:
		phases.append(NamedPlaceholderPhase.new(turn_manager, phase_name))
	return phases


func get_unit_stats_script() -> Script:
	return FortyKUnitStats
