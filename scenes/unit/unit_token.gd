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

@onready var markers_container: Node2D = $Markers
@onready var name_label: Label = $NameLabel
@onready var click_area: Area2D = $ClickArea
@onready var tooltip_area: Control = $TooltipArea
@onready var action_indicator: ColorRect = $ActionIndicator

var _marker_size_px: float = 32.0


func _ready() -> void:
	click_area.input_event.connect(_on_click_area_input_event)


func _process(_delta: float) -> void:
	if dragging:
		position = get_global_mouse_position()
		drag_moved.emit(self, _mouse_position_inches())


func apply_instance(instance: UnitInstance) -> void:
	unit_instance = instance
	var stats: UnitStats = instance.stats
	_marker_size_px = maxf(stats.base_size_mm / 2.0, 16.0)
	name_label.position = Vector2(-40, -_marker_size_px / 2.0 - 18)
	tooltip_area.size = Vector2(_marker_size_px, _marker_size_px)
	tooltip_area.position = -tooltip_area.size / 2.0
	tooltip_area.tooltip_text = _tooltip_text(stats)
	refresh_label()
	sync_position_from_instance()


## Shows the unit's name plus a live models-remaining count, and redraws one
## marker per living model at its actual model_positions offset (see
## UnitInstance.model_positions) — not just a single blob. Called after
## apply_instance() and again whenever the unit takes damage.
func refresh_label() -> void:
	if not unit_instance:
		return
	name_label.text = "%s (%d)" % [unit_instance.stats.display_name, unit_instance.models_alive]
	_rebuild_markers()


func _rebuild_markers() -> void:
	for child in markers_container.get_children():
		child.queue_free()
	for model_position in unit_instance.model_positions:
		var marker := ColorRect.new()
		marker.size = Vector2(_marker_size_px, _marker_size_px)
		var offset_inches: Vector2 = model_position - unit_instance.position_inches
		marker.position = offset_inches * BoardScale.PIXELS_PER_INCH - marker.size / 2.0
		marker.color = Color(0.2, 0.6, 1, 1)
		markers_container.add_child(marker)


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


## Gold tint marking the currently selected attacker (first click of the
## two-click shoot/charge/fight flow).
func set_selected(selected: bool) -> void:
	modulate = Color(1.0, 0.9, 0.4) if selected else Color(1, 1, 1)


## "Who can act" indicator (Phase 5e) — a small gold dot above the unit, on
## while it's this player's turn and the unit still has an action pending
## for the current phase (see main.gd's _pending_units_for_current_phase()).
func set_can_act_indicator(can_act: bool) -> void:
	action_indicator.visible = can_act


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


## Keywords plus the first weapon's special rules — a plain-text hint, not a
## real aura/ability mechanic (there is no range/effect data in core/ for
## that yet).
func _tooltip_text(stats: UnitStats) -> String:
	var words: Array = []
	for keyword in stats.keywords:
		words.append(String(keyword))
	if not stats.weapons.is_empty():
		for rule in stats.weapons[0].special_rules:
			words.append(String(rule))
	return ", ".join(words)
