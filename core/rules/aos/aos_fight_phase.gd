## AoS4 Combat Phase. Per warhammer_age_of_sigmar_4.md section 5 players take
## turns choosing units to fight, starting with the player whose turn it is,
## and the document gives charging units no fight-first priority.
class_name AoSFightPhase
extends FightPhaseBase


func get_phase_name() -> StringName:
	return &"Combat Phase"


func _chargers_fight_first() -> bool:
	return false


func _first_activating_player() -> int:
	return turn_manager.active_player
