## AoS4 End Phase. Per warhammer_age_of_sigmar_4.md section 1 ("Отмена
## Battleshock: Фазы боевого шока больше нет") and section 3.6, Battleshock
## no longer exists in AoS4 at all — this phase does NOT roll it, unlike an
## earlier (AoS3-based) version of this class. What it does instead is score
## objective control (Phase 5d).
class_name AoSEndPhase
extends GamePhase


func get_phase_name() -> StringName:
	return &"End Phase"


func on_enter() -> void:
	ObjectiveScoring.score_objectives(turn_manager.match_state)
