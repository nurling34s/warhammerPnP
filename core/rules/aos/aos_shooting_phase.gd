## AoS4 Shooting Phase. Uses real nearest-model-to-nearest-model geometry for
## range/LoS (see UnitInstance.model_positions) instead of the shared base's
## anchor-point default — 40k keeps the anchor-point behavior for now.
class_name AoSShootingPhase
extends ShootingPhaseBase


func _range_distance(attacker: UnitInstance, target: UnitInstance) -> float:
	return attacker.nearest_edge_distance_to(target)


func _los_endpoints(attacker: UnitInstance, target: UnitInstance) -> Dictionary:
	return {
		"from": attacker.nearest_model_point_to(target),
		"to": target.nearest_model_point_to(attacker),
	}
