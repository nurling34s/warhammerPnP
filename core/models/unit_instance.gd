## Mutable, per-match runtime state for one unit on the board. Split from the
## immutable, shared UnitStats Resource so in-match mutations (position,
## turn flags, casualties) never leak into the cached Resource that other
## instances of the same unit type reference.
class_name UnitInstance
extends RefCounted

var stats: UnitStats
var owner_player: int = 0
var position_inches: Vector2 = Vector2.ZERO
var facing_degrees: float = 0.0
var is_destroyed: bool = false

## One entry per living model, in allocation order (index 0 = "next model
## to take damage"). models_alive is kept in sync with this array's size —
## treat model_wounds_remaining as the source of truth, models_alive as a
## convenience read.
var model_wounds_remaining: Array[int] = []
var models_alive: int = 0

var models_lost_this_turn: int = 0
var battleshock_failed_this_turn: bool = false

var has_deployed: bool = false
var has_moved: bool = false
var has_run_or_advanced: bool = false
var has_charged: bool = false
var has_fallen_back: bool = false
var has_shot: bool = false


func _init(unit_stats: UnitStats, player: int) -> void:
	stats = unit_stats
	owner_player = player
	model_wounds_remaining = []
	for _i in unit_stats.models_per_unit:
		model_wounds_remaining.append(unit_stats.health_per_model)
	models_alive = model_wounds_remaining.size()


## Flat for now; Phase 3+ may subtract terrain penalties or model a
## half-move, so callers should always go through this rather than reading
## stats.move_inches directly.
func remaining_move_inches() -> float:
	return stats.move_inches


## Resets the per-turn action flags. Called by MovementPhaseBase.on_enter()
## and (for models_lost_this_turn/battleshock_failed_this_turn) by whichever
## phase precedes the next battleshock check.
func reset_turn_flags() -> void:
	has_moved = false
	has_run_or_advanced = false
	has_charged = false
	has_fallen_back = false
	has_shot = false
	models_lost_this_turn = 0
	battleshock_failed_this_turn = false


## Applies `amount` wounds to the front of the allocation queue, killing and
## removing models as they hit 0 and spilling any remainder onto the next
## model. Returns leftover damage that couldn't be applied because the unit
## was wiped out. This is the one mutator for wounds — allocate_wounds() in
## each ruleset decides ordering, this method does the actual bookkeeping.
func apply_damage_to_next_model(amount: int) -> int:
	var remaining_damage := amount
	while remaining_damage > 0 and not model_wounds_remaining.is_empty():
		var front: int = model_wounds_remaining[0]
		if remaining_damage >= front:
			remaining_damage -= front
			model_wounds_remaining.pop_front()
			models_lost_this_turn += 1
		else:
			model_wounds_remaining[0] = front - remaining_damage
			remaining_damage = 0

	models_alive = model_wounds_remaining.size()
	is_destroyed = models_alive == 0
	return remaining_damage


## Removes exactly one more model (or as many as remain, if fewer), for the
## minimal Battleshock-failure placeholder consequence. Does not roll dice.
func remove_one_model() -> void:
	if not model_wounds_remaining.is_empty():
		model_wounds_remaining.pop_front()
		models_alive = model_wounds_remaining.size()
		is_destroyed = models_alive == 0
