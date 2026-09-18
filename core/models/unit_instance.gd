## Mutable, per-match runtime state for one unit on the board. Split from the
## immutable, shared UnitStats Resource so in-match mutations (position,
## turn flags, casualties) never leak into the cached Resource that other
## instances of the same unit type reference.
##
## Per-model wound tracking, status effects, and buffs are Phase 3/4 work —
## for now a unit is treated as a single point plus a model count.
class_name UnitInstance
extends RefCounted

var stats: UnitStats
var owner_player: int = 0
var position_inches: Vector2 = Vector2.ZERO
var facing_degrees: float = 0.0
var models_alive: int = 0
var is_destroyed: bool = false

var has_deployed: bool = false
var has_moved: bool = false
var has_run_or_advanced: bool = false
var has_charged: bool = false
var has_fallen_back: bool = false


func _init(unit_stats: UnitStats, player: int) -> void:
	stats = unit_stats
	owner_player = player
	models_alive = unit_stats.models_per_unit


## Flat for now; Phase 3+ may subtract terrain penalties or model a
## half-move, so callers should always go through this rather than reading
## stats.move_inches directly.
func remaining_move_inches() -> float:
	return stats.move_inches


## Resets the per-turn action flags. Called by MovementPhaseBase.on_enter().
func reset_turn_flags() -> void:
	has_moved = false
	has_run_or_advanced = false
	has_charged = false
	has_fallen_back = false
