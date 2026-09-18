## Value object holding the outcome of a batch of dice rolls against a target
## number, including which rolls were rerolled and which counted as crits.
## Feeds CombatLog directly.
class_name RollResult
extends RefCounted

var target_number: int = 0
var raw_rolls: Array[int] = []       ## dice as they landed, before any reroll
var final_rolls: Array[int] = []     ## after rerolls, before the +/- modifier
var modified_rolls: Array[int] = []  ## after the +/- modifier is applied
var successes: int = 0
var critical_successes: int = 0      ## count of unmodified rolls >= crit_threshold
var modifier_notes: Array[String] = []


func success_count() -> int:
	return successes
