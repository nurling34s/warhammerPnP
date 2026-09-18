## Draws a translucent rectangle per DeploymentZone so players can see where
## they're allowed to place units. Purely visual — DeploymentManager owns
## the actual legality check.
class_name DeploymentZoneOverlay
extends Node2D

var zones: Array[DeploymentZone] = []


func set_zones(new_zones: Array[DeploymentZone]) -> void:
	zones = new_zones
	queue_redraw()


func _draw() -> void:
	for zone in zones:
		var fill_color := Color(0.2, 0.4, 1.0, 0.15) if zone.owner_player == 0 else Color(1.0, 0.3, 0.3, 0.15)
		var border_color := fill_color.lightened(0.4)
		var rect_px := Rect2(
			zone.rect_inches.position * BoardScale.PIXELS_PER_INCH,
			zone.rect_inches.size * BoardScale.PIXELS_PER_INCH
		)
		draw_rect(rect_px, fill_color, true)
		draw_rect(rect_px, border_color, false, 2.0)
