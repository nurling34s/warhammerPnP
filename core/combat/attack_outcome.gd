## Bag of results from one AttackResolver.resolve_attack() call — what a
## future combat-log UI (Phase 4) and any scene-layer feedback read.
class_name AttackOutcome
extends RefCounted

var to_hit: RollResult
var to_wound: RollResult
var save: RollResult
var allocation: Array
var models_slain: int


func _init(hit: RollResult, wound: RollResult, save_result: RollResult, alloc: Array, slain: int) -> void:
	to_hit = hit
	to_wound = wound
	save = save_result
	allocation = alloc
	models_slain = slain


## Number of failed saves that generated a damage event — i.e. how many
## points of damage were rolled for, whether or not they killed a model.
func failed_save_count() -> int:
	return to_wound.successes - save.successes
