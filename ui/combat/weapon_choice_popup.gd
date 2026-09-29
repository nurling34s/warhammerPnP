## Small modal-ish popup listing a unit's weapon options for the attack the
## player just declared (shoot or fight). Only shown when there's an actual
## choice to make — main.gd skips it entirely when a unit has just one
## matching weapon, so the common case stays a plain two-click flow.
class_name WeaponChoicePopup
extends PanelContainer

signal weapon_chosen(weapon: WeaponProfile)

@onready var list: VBoxContainer = $Layout/List

var _buttons: Array[Button] = []


func show_choices(weapons: Array[WeaponProfile]) -> void:
	for button in _buttons:
		button.queue_free()
	_buttons.clear()

	for weapon in weapons:
		var button := Button.new()
		button.text = "%s (A%s, Hit %d+)" % [weapon.weapon_name, weapon.attacks, weapon.to_hit_stat]
		button.pressed.connect(_on_weapon_button_pressed.bind(weapon))
		list.add_child(button)
		_buttons.append(button)

	visible = true


func _on_weapon_button_pressed(weapon: WeaponProfile) -> void:
	visible = false
	weapon_chosen.emit(weapon)
