## Shared Shooting Phase logic: range + line-of-sight validation and
## declaring an attack. AoSShootingPhase/FortyKShootingPhase currently add
## no divergent behavior — the seam exists for when they need to.
class_name ShootingPhaseBase
extends GamePhase


func get_phase_name() -> StringName:
	return &"Shooting Phase"


func on_enter() -> void:
	for unit in turn_manager.match_state.units_for_player(turn_manager.active_player):
		unit.has_shot = false


## Pure check — does not mutate anything. Returns {"ok": bool, "reason": String}.
func can_shoot(attacker: UnitInstance, weapon: WeaponProfile, target: UnitInstance, terrain: Array[TerrainPiece]) -> Dictionary:
	if attacker.has_shot:
		return {"ok": false, "reason": "already_shot"}
	if attacker.has_fallen_back:
		return {"ok": false, "reason": "cannot_shoot_after_falling_back"}

	var distance: float = _range_distance(attacker, target)
	if distance > weapon.range_inches:
		return {"ok": false, "reason": "out_of_range"}

	var los := _los_endpoints(attacker, target)
	if LineOfSight.is_blocked(los.from, los.to, terrain):
		return {"ok": false, "reason": "no_line_of_sight"}

	return {"ok": true, "reason": ""}


## Distance used for weapon range. Anchor-point distance by default; override
## where per-model geometry exists (see AoSShootingPhase).
func _range_distance(attacker: UnitInstance, target: UnitInstance) -> float:
	return attacker.position_inches.distance_to(target.position_inches)


## Endpoints used for the LoS check. Anchor points by default; override
## where per-model geometry exists (see AoSShootingPhase).
func _los_endpoints(attacker: UnitInstance, target: UnitInstance) -> Dictionary:
	return {"from": attacker.position_inches, "to": target.position_inches}


func get_valid_targets(attacker: UnitInstance, weapon: WeaponProfile, all_units: Array, terrain: Array[TerrainPiece]) -> Array[UnitInstance]:
	var targets: Array[UnitInstance] = []
	for other in all_units:
		if other == attacker or other.owner_player == attacker.owner_player or other.is_destroyed:
			continue
		if can_shoot(attacker, weapon, other, terrain).ok:
			targets.append(other)
	return targets


## Validates and, on success, mutates attacker.has_shot and resolves the
## attack via `resolver`. Returns {"ok": bool, "reason": String, "outcome": AttackOutcome}.
func declare_shoot(attacker: UnitInstance, weapon: WeaponProfile, target: UnitInstance, terrain: Array[TerrainPiece], resolver: AttackResolver) -> Dictionary:
	var check := can_shoot(attacker, weapon, target, terrain)
	if not check.ok:
		return {"ok": false, "reason": check.reason, "outcome": null}

	attacker.has_shot = true
	var range_inches: float = _range_distance(attacker, target)
	var outcome: AttackOutcome = resolver.resolve_attack(attacker, weapon, target, {"range_inches": range_inches})
	return {"ok": true, "reason": "", "outcome": outcome}
