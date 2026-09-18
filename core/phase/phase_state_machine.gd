## Advances through an ordered list of GamePhase instances for one player's
## turn, emitting `phase_changed` on every transition. When the list is
## exhausted it hands control back to the TurnManager to start the next turn.
class_name PhaseStateMachine
extends RefCounted

signal phase_changed(phase: GamePhase)

var turn_manager: TurnManager
var current_phase: GamePhase
var _phases: Array[GamePhase] = []
var _index: int = -1


func _init(tm: TurnManager) -> void:
	turn_manager = tm


func start(phases: Array[GamePhase]) -> void:
	_phases = phases
	_index = -1
	_advance()


func _advance() -> void:
	if current_phase and current_phase.phase_completed.is_connected(_on_phase_completed):
		current_phase.phase_completed.disconnect(_on_phase_completed)

	_index += 1
	if _index >= _phases.size():
		current_phase = null
		turn_manager.advance_player_turn()
		return

	current_phase = _phases[_index]
	current_phase.phase_completed.connect(_on_phase_completed)
	current_phase.on_enter()
	phase_changed.emit(current_phase)


func _on_phase_completed() -> void:
	_advance()
