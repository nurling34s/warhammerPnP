## Parses/rolls the small dice-notation strings used by WeaponProfile
## (attacks/strength_or_damage/damage): plain flat numbers ("1", "3"), a
## single die ("D3", "D6"), or multiple dice ("2D6"). Case-insensitive.
class_name DiceNotation
extends RefCounted


## Returns {"fixed": int, "dice_count": int, "dice_sides": int}. A flat
## number parses to {fixed: N, dice_count: 0, dice_sides: 0}.
static func parse(spec: String) -> Dictionary:
	var normalized := spec.strip_edges().to_upper()
	var d_index := normalized.find("D")
	if d_index == -1:
		return {"fixed": int(normalized), "dice_count": 0, "dice_sides": 0}

	var prefix := normalized.substr(0, d_index)
	var suffix := normalized.substr(d_index + 1)
	var dice_count: int = int(prefix) if prefix != "" else 1
	return {"fixed": 0, "dice_count": dice_count, "dice_sides": int(suffix)}


## Rolls the given spec against `dice`, returning a single resolved int.
static func roll(spec: String, dice: DiceRoller) -> int:
	var parsed := parse(spec)
	if parsed.dice_count <= 0:
		return parsed.fixed

	var total: int = parsed.fixed
	for value in dice.roll(parsed.dice_count, parsed.dice_sides):
		total += value
	return total
