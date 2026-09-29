## 40k 11th ed Fight Phase. Uses real nearest-model geometry for
## engagement-range and pile-in aim (see UnitInstance.model_positions) —
## ported from AoSFightPhase in Phase 5f now that per-model positions are
## proven out.
class_name FortyKFightPhase
extends FightPhaseBase


func get_phase_name() -> StringName:
	return &"Fight Phase"


func _engagement_distance(attacker: UnitInstance, target: UnitInstance) -> float:
	return attacker.nearest_model_distance_to(target)


func _pile_in_aim_point(unit: UnitInstance, target_enemy: UnitInstance) -> Vector2:
	return target_enemy.nearest_model_point_to(unit)
