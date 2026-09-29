## Shown by main.gd when the active player tries to end a phase while some of
## their units could still act (haven't shot/fought/moved) — a safety net
## against accidentally skipping an action, per Phase 5e.
class_name EndPhaseConfirmPopup
extends PanelContainer

signal confirmed
signal cancelled

@onready var message_label: Label = $Layout/Message
@onready var confirm_button: Button = $Layout/Buttons/ConfirmButton
@onready var cancel_button: Button = $Layout/Buttons/CancelButton


func _ready() -> void:
	confirm_button.pressed.connect(func(): visible = false; confirmed.emit())
	cancel_button.pressed.connect(func(): visible = false; cancelled.emit())


func show_with_pending_count(pending_count: int) -> void:
	message_label.text = "%d unit(s) haven't acted this phase yet. End phase anyway?" % pending_count
	visible = true
