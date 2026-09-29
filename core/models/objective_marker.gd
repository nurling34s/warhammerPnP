## A capturable objective on the board (AoS4 only — 40k stays frozen without
## objectives for now). `controlled_by` is runtime state, recomputed each End
## Phase by ObjectiveScoring; -1 means uncontrolled/contested.
class_name ObjectiveMarker
extends Resource

@export var objective_id: StringName = &""
@export var position_inches: Vector2 = Vector2.ZERO
@export var radius_inches: float = 6.0

var controlled_by: int = -1
