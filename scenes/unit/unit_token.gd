## Node2D rendering of a single UnitInstance on the board. This is the
## scene-tree consumer side of the "core/ has no scene dependency" split — it
## only reads data out of UnitInstance/UnitStats and draws it, plus drives
## drag-to-move input; all rules validation happens in core/ and is only
## ever read here to drive color feedback.
class_name UnitToken
extends Node2D

signal drag_started(token: UnitToken)
signal drag_moved(token: UnitToken, position_inches: Vector2)
signal drag_ended(token: UnitToken, position_inches: Vector2)

var unit_instance: UnitInstance
var dragging: bool = false

@onready var marker: ColorRect = $Marker
@onready var name_label: Label = $NameLabel
@onready var click_area: Area2D = $ClickArea


func _ready() -> void:
	click_area.input_event.connect(_on_click_area_input_event)


func _process(_delta: float) -> void:
	if dragging:
		position = get_global_mouse_position()
		drag_moved.emit(self, _mouse_position_inches())


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
## pixels). Called after apply_instance() and again after a move attempt
## (successful or not) to snap the token back to the authoritative position.
func sync_position_from_instance() -> void:
	if unit_instance:
		position = unit_instance.position_inches * BoardScale.PIXELS_PER_INCH


## Tints the token to show whether the currently-dragged-to position is a
## legal move. Purely visual — the caller already ran the real check in core/.
func set_drag_feedback(valid: bool) -> void:
	modulate = Color(0.5, 1.0, 0.5) if valid else Color(1.0, 0.5, 0.5)


func clear_drag_feedback() -> void:
	modulate = Color(1, 1, 1)


## Deprecated: kept as a thin wrapper so old call sites/tests that only had
## a UnitStats on hand keep working. Prefer apply_instance().
func apply_stats(stats: UnitStats, owner_player: int = 0) -> void:
	apply_instance(UnitInstance.new(stats, owner_player))


func _on_click_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not dragging:
			dragging = true
			drag_started.emit(self)
		elif not event.pressed and dragging:
			dragging = false
			drag_ended.emit(self, _mouse_position_inches())


func _mouse_position_inches() -> Vector2:
	return get_global_mouse_position() / BoardScale.PIXELS_PER_INCH
