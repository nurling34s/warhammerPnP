## AoS4 Combat Phase. Uses real nearest-model geometry for engagement-range
## and pile-in aim (see UnitInstance.model_positions) — 40k keeps the shared
## base's anchor-point behavior for now.
class_name AoSFightPhase
extends FightPhaseBase


func get_phase_name() -> StringName:
	return &"Combat Phase"


func _engagement_distance(attacker: UnitInstance, target: UnitInstance) -> float:
	return attacker.nearest_model_distance_to(target)


func _pile_in_aim_point(unit: UnitInstance, target_enemy: UnitInstance) -> Vector2:
	return target_enemy.nearest_model_point_to(unit)
