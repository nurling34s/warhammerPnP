## Node2D rendering of a single UnitInstance on the board. This is the
## scene-tree consumer side of the "core/ has no scene dependency" split — it
## only reads data out of UnitInstance/UnitStats and draws it, no rules
## logic lives here.
class_name UnitToken
extends Node2D

var unit_instance: UnitInstance

@onready var marker: ColorRect = $Marker
@onready var name_label: Label = $NameLabel


func apply_instance(instance: UnitInstance) -> void:
	unit_instance = instance
	var stats: UnitStats = instance.stats
	var size_px: float = maxf(stats.base_size_mm / 2.0, 16.0)
	marker.size = Vector2(size_px, size_px)
	marker.position = -marker.size / 2.0
	name_label.text = stats.display_name
	name_label.position = Vector2(-40, marker.position.y - 18)
	sync_position_from_instance()


## Moves this token to match unit_instance.position_inches (converted to
## pixels). Called after apply_instance() and again whenever the instance's
## position changes (e.g. after a validated move).
func sync_position_from_instance() -> void:
	if unit_instance:
		position = unit_instance.position_inches * BoardScale.PIXELS_PER_INCH


## Deprecated: kept as a thin wrapper so old call sites/tests that only had
## a UnitStats on hand keep working. Prefer apply_instance().
func apply_stats(stats: UnitStats, owner_player: int = 0) -> void:
	apply_instance(UnitInstance.new(stats, owner_player))
