## Root of the 2D tabletop. Emits `clicked` with the click position converted
## to inches so scenes/main.gd can drive deployment placement and (later)
## drag-to-move without any rules logic living here.
class_name Board
extends Node2D

signal clicked(position_inches: Vector2)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var position_inches: Vector2 = get_global_mouse_position() / BoardScale.PIXELS_PER_INCH
		clicked.emit(position_inches)
