## Drives the one-time pre-match deployment step: players place their units
## within their own DeploymentZone before TurnManager.start_match() begins.
## Not a GamePhase — deployment happens once, not every turn, so it doesn't
## fit PhaseStateMachine's per-player-turn loop.
class_name DeploymentManager
extends RefCounted

signal deployment_complete
signal turn_to_deploy_changed(player: int)

var zones: Array[DeploymentZone] = []
var match_state: MatchState
var pending_units: Array[UnitInstance] = []
var current_deploying_player: int = 0


func _init(deployment_zones: Array[DeploymentZone], state: MatchState, units_to_deploy: Array[UnitInstance] = []) -> void:
	zones = deployment_zones
	match_state = state
	pending_units = units_to_deploy.duplicate()


func zone_for_player(player: int) -> DeploymentZone:
	for zone in zones:
		if zone.owner_player == player:
			return zone
	return null


## Pure check — does not mutate anything.
func can_place(unit: UnitInstance, position_inches: Vector2) -> bool:
	var zone := zone_for_player(unit.owner_player)
	return zone != null and zone.rect_inches.has_point(position_inches)


## Places the unit if legal, adds it to match_state, and advances whose turn
## it is to deploy. Returns false without mutating anything if illegal.
func place_unit(unit: UnitInstance, position_inches: Vector2) -> bool:
	if not can_place(unit, position_inches):
		return false

	unit.position_inches = position_inches
	unit.has_deployed = true
	match_state.units.append(unit)
	pending_units.erase(unit)

	if pending_units.is_empty():
		deployment_complete.emit()
	else:
		current_deploying_player = 1 - current_deploying_player
		turn_to_deploy_changed.emit(current_deploying_player)
	return true
