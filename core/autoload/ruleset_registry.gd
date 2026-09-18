## Holds the ruleset chosen for the current match (set from RulesetSelect.tscn)
## so the rest of the game asks this registry instead of branching on a
## ruleset enum anywhere else in the codebase.
extends Node

var active: RulesetProvider = null

var _providers_by_id: Dictionary = {
	&"aos4": AoSRuleset,
	&"forty_k_11e": FortyKRuleset,
}


func set_active_by_id(ruleset_id: StringName) -> void:
	var script: Script = _providers_by_id.get(ruleset_id)
	assert(script != null, "Unknown ruleset id: %s" % ruleset_id)
	active = script.new()
