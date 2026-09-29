## Mutable, per-match runtime state for one unit on the board. Split from the
## immutable, shared UnitStats Resource so in-match mutations (position,
## turn flags, casualties) never leak into the cached Resource that other
## instances of the same unit type reference.
class_name UnitInstance
extends RefCounted

var stats: UnitStats
var owner_player: int = 0
## The unit's anchor point. Setting it translates every entry in
## model_positions by the same delta, i.e. the formation still moves as one
## rigid group — see model_positions doc below for why that's a deliberate,
## bounded simplification rather than true per-model movement.
var position_inches: Vector2 = Vector2.ZERO:
	set(value):
		var delta: Vector2 = value - position_inches
		position_inches = value
		for i in model_positions.size():
			model_positions[i] += delta
var facing_degrees: float = 0.0
var is_destroyed: bool = false

## One entry per living model, in allocation order (index 0 = "next model
## to take damage"). models_alive is kept in sync with this array's size —
## treat model_wounds_remaining as the source of truth, models_alive as a
## convenience read.
var model_wounds_remaining: Array[int] = []
var models_alive: int = 0

## Absolute per-model positions, one entry per living model, same index
## order as model_wounds_remaining (index 0 dies first). Auto-generated as a
## fixed grid formation around position_inches and moved rigidly with it —
## there is no UI yet to drag individual models within a unit, so this is
## honest per-model *geometry* (real nearest-model distances for coherency/
## engagement/LoS/pile-in) without claiming independent per-model movement.
var model_positions: Array[Vector2] = []

## AoS4 core-rulebook coherency distance between models of the same unit —
## verify against the current rulebook before treating this as final.
const MODEL_SPACING_INCHES: float = 1.0

var models_lost_this_turn: int = 0
var battleshock_failed_this_turn: bool = false

var has_deployed: bool = false
var has_moved: bool = false
var has_run_or_advanced: bool = false
var has_charged: bool = false
## True once the unit has declared a charge this turn, successful or not —
## a unit only gets one charge attempt per Charge Phase. has_charged (which
## grants FightPhaseBase's chargers-first priority) is true only on success.
var has_attempted_charge: bool = false
var has_fallen_back: bool = false
var has_shot: bool = false
var has_fought: bool = false


func _init(unit_stats: UnitStats, player: int) -> void:
	stats = unit_stats
	owner_player = player
	model_wounds_remaining = []
	for _i in unit_stats.models_per_unit:
		model_wounds_remaining.append(unit_stats.health_per_model)
	models_alive = model_wounds_remaining.size()
	model_positions = _build_formation()


## Simple grid formation, spaced at exactly MODEL_SPACING_INCHES so the
## auto-generated formation always starts coherent (see check_unit_coherency).
func _build_formation() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var per_row: int = maxi(1, ceili(sqrt(float(models_alive))))
	for i in models_alive:
		var row := i / per_row
		var col := i % per_row
		positions.append(position_inches + Vector2(col, row) * MODEL_SPACING_INCHES)
	return positions


## Nearest distance between any of this unit's models and any of `other`'s —
## the honest per-model measurement backing AoS4's coherency/engagement/LoS
## checks (see model_positions doc). Falls back to the anchor points if
## either unit has no models left, which should not happen in practice.
func nearest_model_distance_to(other: UnitInstance) -> float:
	if model_positions.is_empty() or other.model_positions.is_empty():
		return position_inches.distance_to(other.position_inches)
	var best := INF
	for p in model_positions:
		for q in other.model_positions:
			best = minf(best, p.distance_to(q))
	return best


## Radius of one model's base, in inches.
func model_radius_inches() -> float:
	return stats.base_size_mm / 2.0 / 25.4


## Gap between the nearest bases (edge to edge, 0 when they touch) — what the
## rulebooks' weapon range and engagement range actually measure, as opposed
## to nearest_model_distance_to()'s centre-to-centre distance.
func nearest_edge_distance_to(other: UnitInstance) -> float:
	return maxf(0.0, nearest_model_distance_to(other) - model_radius_inches() - other.model_radius_inches())


## The point (one of this unit's model_positions) closest to any of
## `other`'s models — used as the "from"/"to" endpoint for per-model LoS and
## as the pile-in aim point.
func nearest_model_point_to(other: UnitInstance) -> Vector2:
	if model_positions.is_empty() or other.model_positions.is_empty():
		return position_inches
	var best_distance := INF
	var best_point := position_inches
	for p in model_positions:
		for q in other.model_positions:
			var distance: float = p.distance_to(q)
			if distance < best_distance:
				best_distance = distance
				best_point = p
	return best_point


## True if every model in the unit has at least one other model of the same
## unit within `spacing_inches` — the geometric core of AoS4 unit coherency.
## Given the auto-generated, rigidly-moving formation (see model_positions
## doc), this is essentially always true today; it becomes a real check once
## independent per-model movement exists.
func is_coherent(spacing_inches: float) -> bool:
	if model_positions.size() <= 1:
		return true
	for i in model_positions.size():
		var has_neighbor := false
		for j in model_positions.size():
			if i != j and model_positions[i].distance_to(model_positions[j]) <= spacing_inches:
				has_neighbor = true
				break
		if not has_neighbor:
			return false
	return true


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
	has_attempted_charge = false
	has_fallen_back = false
	has_shot = false
	has_fought = false
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
			if not model_positions.is_empty():
				model_positions.pop_front()
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
		if not model_positions.is_empty():
			model_positions.pop_front()
		models_alive = model_wounds_remaining.size()
		is_destroyed = models_alive == 0
