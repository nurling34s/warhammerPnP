## 40k 11th ed Fight Phase: units that charged fight first, then players
## alternate starting with the player whose turn it is NOT (placeholder
## tie-break carried over from the original queue — verify against the
## current core rulebook).
class_name FortyKFightPhase
extends FightPhaseBase


func get_phase_name() -> StringName:
	return &"Fight Phase"


func _chargers_fight_first() -> bool:
	return true


func _first_activating_player() -> int:
	return 1 - turn_manager.active_player
