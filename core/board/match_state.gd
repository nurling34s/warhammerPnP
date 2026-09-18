## Registry of every UnitInstance on the board for the current match. Needed
## because zone-of-control and coherency checks are inherently relational —
## they need to know about every unit, not just the one being queried.
class_name MatchState
extends RefCounted

var units: Array[UnitInstance] = []


func units_for_player(player: int) -> Array[UnitInstance]:
	return units.filter(func(u: UnitInstance): return u.owner_player == player and not u.is_destroyed)


func enemy_units_of(unit: UnitInstance) -> Array[UnitInstance]:
	return units.filter(func(u: UnitInstance): return u.owner_player != unit.owner_player and not u.is_destroyed)
