## A GamePhase with no gameplay logic yet — just a name. Used by both
## rulesets' build_phase_sequence() until each phase grows its own real
## subclass (movement rules, shooting pipeline, etc. — Phase 2/3 work).
class_name NamedPlaceholderPhase
extends GamePhase

var _phase_name: StringName


func _init(tm: TurnManager, phase_name: StringName) -> void:
	super._init(tm)
	_phase_name = phase_name


func get_phase_name() -> StringName:
	return _phase_name
