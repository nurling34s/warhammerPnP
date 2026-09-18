## Minimal terrain data shape. `blocks_movement` is used now (Phase 2
## movement validation); `blocks_line_of_sight`/`provides_cover` are inert
## fields until the Phase 3 shooting pipeline reads them — added now so
## terrain data doesn't need a schema migration later.
class_name TerrainPiece
extends Resource

@export var terrain_id: StringName = &""
@export var footprint_inches: Rect2 = Rect2()
@export var blocks_movement: bool = false
@export var blocks_line_of_sight: bool = false
@export var provides_cover: bool = false
