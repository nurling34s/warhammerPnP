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
	return [
		NamedPlaceholderPhase.new(turn_manager, &"Hero Phase"),
		AoSMovementPhase.new(turn_manager),
		NamedPlaceholderPhase.new(turn_manager, &"Shooting Phase"),
		NamedPlaceholderPhase.new(turn_manager, &"Charge Phase"),
		NamedPlaceholderPhase.new(turn_manager, &"Combat Phase"),
		NamedPlaceholderPhase.new(turn_manager, &"End Phase"),
	]


func get_unit_stats_script() -> Script:
	return AoSUnitStats


## AoS4 engagement range is 3" horizontally from the unit's models
## (round/placeholder figure — verify against the current core rulebook).
func get_engagement_range_inches() -> float:
	return 3.0


func is_in_engagement_range(unit: UnitInstance, all_units: Array) -> bool:
	var range_inches := get_engagement_range_inches()
	for other in all_units:
		if other == unit or other.owner_player == unit.owner_player or other.is_destroyed:
			continue
		if unit.position_inches.distance_to(other.position_inches) <= range_inches:
			return true
	return false
