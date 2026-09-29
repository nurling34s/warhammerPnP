## 40k 11th ed Shooting Phase. Uses real nearest-model-to-nearest-model
## geometry for range/LoS (see UnitInstance.model_positions) — ported from
## AoSShootingPhase in Phase 5f now that per-model positions are proven out.
class_name FortyKShootingPhase
extends ShootingPhaseBase


func _range_distance(attacker: UnitInstance, target: UnitInstance) -> float:
	return attacker.nearest_model_distance_to(target)


func _los_endpoints(attacker: UnitInstance, target: UnitInstance) -> Dictionary:
	return {
		"from": attacker.nearest_model_point_to(target),
		"to": target.nearest_model_point_to(attacker),
	}
