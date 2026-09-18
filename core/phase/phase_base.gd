## Abstract base for one phase of a turn (Hero/Movement/Shooting/... for AoS4,
## Command/Movement/Shooting/... for 40k 11th ed). Concrete phases live under
## core/rules/aos/ and core/rules/forty_k/, or as shared bases in core/phase/.
class_name GamePhase
extends RefCounted

signal phase_completed

var turn_manager


func _init(tm) -> void:
	turn_manager = tm


func get_phase_name() -> StringName:
	assert(false, "GamePhase.get_phase_name() must be overridden")
	return &""


## Called once when the phase becomes active. Override for setup
## (e.g. resetting has_moved/has_shot flags on units).
func on_enter() -> void:
	pass


## Called once when the phase ends, before the next phase's on_enter().
func on_exit() -> void:
	pass


## Action identifiers the UI should expose right now for the given unit.
func get_available_actions(unit) -> Array:
	return []


## Called by the UI when the active player declares this phase finished.
func request_end_phase() -> void:
	on_exit()
	phase_completed.emit()
