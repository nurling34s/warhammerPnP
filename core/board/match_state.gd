## Registry of every UnitInstance and TerrainPiece on the board for the
## current match. Units are tracked here because zone-of-control and
## coherency checks are inherently relational — they need to know about
## every unit, not just the one being queried. Terrain lives here too since
## it's whole-match, static board state that movement validation must see.
class_name MatchState
extends RefCounted

var units: Array[UnitInstance] = []
var terrain: Array[TerrainPiece] = []


func units_for_player(player: int) -> Array[UnitInstance]:
	return units.filter(func(u: UnitInstance): return u.owner_player == player and not u.is_destroyed)


func enemy_units_of(unit: UnitInstance) -> Array[UnitInstance]:
	return units.filter(func(u: UnitInstance): return u.owner_player != unit.owner_player and not u.is_destroyed)
