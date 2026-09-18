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
	return [
		NamedPlaceholderPhase.new(turn_manager, &"Command Phase"),
		FortyKMovementPhase.new(turn_manager),
		NamedPlaceholderPhase.new(turn_manager, &"Shooting Phase"),
		NamedPlaceholderPhase.new(turn_manager, &"Charge Phase"),
		NamedPlaceholderPhase.new(turn_manager, &"Fight Phase"),
		NamedPlaceholderPhase.new(turn_manager, &"Battle-shock Phase"),
	]


func get_unit_stats_script() -> Script:
	return FortyKUnitStats


## 40k 11th ed engagement range is 1" horizontally (round/placeholder figure;
## the real rule also has a vertical component for multi-level terrain,
## deferred until per-model positions exist — verify against the current
## core rulebook before real army data is entered).
func get_engagement_range_inches() -> float:
	return 1.0


func is_in_engagement_range(unit: UnitInstance, all_units: Array) -> bool:
	var range_inches := get_engagement_range_inches()
	for other in all_units:
		if other == unit or other.owner_player == unit.owner_player or other.is_destroyed:
			continue
		if unit.position_inches.distance_to(other.position_inches) <= range_inches:
			return true
	return false
