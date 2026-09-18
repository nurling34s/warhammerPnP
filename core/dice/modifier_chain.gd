## Composable dice-modification rules for a single roll step (to-hit, to-wound,
## save, ...): rerolls, a flat +/- modifier, and a crit threshold/effect.
##
## Follows the standard modern-edition convention used by both AoS4 and 40k
## 11th ed: an unmodified roll of 1 always fails and an unmodified roll of 6
## always succeeds, regardless of modifiers (modifiers still shift every other
## result, and are clamped so a modified value never reports below 1 or above 6).
class_name ModifierChain
extends RefCounted

enum Reroll { NONE, ONES, FAILED, ALL_ONCE }

var flat_modifier: int = 0
var reroll_rule: Reroll = Reroll.NONE
var crit_threshold: int = 6
var crit_effect: StringName = &""  ## e.g. &"extra_hit", &"mortal_wound" — read by callers


func apply(dice: DiceRoller, target_number: int, count: int) -> RollResult:
	var result := RollResult.new()
	result.target_number = target_number

	var raw := dice.roll(count)
	result.raw_rolls = raw.duplicate()

	for i in raw.size():
		var value: int = raw[i]

		if _should_reroll(value, target_number):
			value = dice.roll_single()
			result.modifier_notes.append("rerolled %d" % raw[i])

		result.final_rolls.append(value)

		if value >= crit_threshold:
			result.critical_successes += 1

		var modified: int = value
		if value != 1 and value != 6:
			modified = clampi(value + flat_modifier, 1, 6)
		result.modified_rolls.append(modified)

		var succeeded: bool
		if value == 1:
			succeeded = false
		elif value == 6:
			succeeded = true
		else:
			succeeded = modified >= target_number
		if succeeded:
			result.successes += 1

	return result


func _should_reroll(value: int, target_number: int) -> bool:
	match reroll_rule:
		Reroll.ONES:
			return value == 1
		Reroll.FAILED:
			return value < target_number
		Reroll.ALL_ONCE:
			return true
		_:
			return false
