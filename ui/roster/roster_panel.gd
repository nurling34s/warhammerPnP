## Read-only list of the active player's units. Purely informational — does
## not replace the existing click-on-token flow for shooting/fighting; it
## only lets the player pick a unit to highlight on the board and preview in
## the UnitCard.
class_name RosterPanel
extends VBoxContainer

signal unit_selected(unit: UnitInstance)

var _buttons: Array[Button] = []


func refresh(units: Array[UnitInstance]) -> void:
	for button in _buttons:
		button.queue_free()
	_buttons.clear()

	for unit in units:
		var button := Button.new()
		button.text = "%s (%d/%d)" % [unit.stats.display_name, unit.models_alive, unit.stats.models_per_unit]
		button.tooltip_text = _keywords_text(unit.stats)
		button.pressed.connect(_on_unit_button_pressed.bind(unit))
		add_child(button)
		_buttons.append(button)


func _on_unit_button_pressed(unit: UnitInstance) -> void:
	unit_selected.emit(unit)


func _keywords_text(stats: UnitStats) -> String:
	var words: Array = []
	for keyword in stats.keywords:
		words.append(String(keyword))
	return ", ".join(words)
