## Node2D rendering of a single UnitStats on the board. This is the scene-tree
## consumer side of the "core/ has no scene dependency" split — it only reads
## data out of UnitStats and draws it, no rules logic lives here.
class_name UnitToken
extends Node2D

var unit_stats: UnitStats

@onready var marker: ColorRect = $Marker
@onready var name_label: Label = $NameLabel


func apply_stats(stats: UnitStats) -> void:
	unit_stats = stats
	var size_px: float = maxf(stats.base_size_mm / 2.0, 16.0)
	marker.size = Vector2(size_px, size_px)
	marker.position = -marker.size / 2.0
	name_label.text = stats.display_name
	name_label.position = Vector2(-40, marker.position.y - 18)
