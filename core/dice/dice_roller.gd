## Thin, seedable wrapper around RandomNumberGenerator so combat math stays
## deterministic and testable. Never reach for a global RNG from core/ code —
## always take a DiceRoller instance as a parameter.
class_name DiceRoller
extends RefCounted

var _rng: RandomNumberGenerator


func _init(seed_value: int = -1) -> void:
	_rng = RandomNumberGenerator.new()
	if seed_value >= 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()


## Rolls n dice of the given number of sides, returns the raw values in order.
func roll(n: int, sides: int = 6) -> Array[int]:
	var results: Array[int] = []
	for _i in n:
		results.append(_rng.randi_range(1, sides))
	return results


func roll_single(sides: int = 6) -> int:
	return roll(1, sides)[0]
