## Boots a match: lets the player pick a ruleset, spawns the board and one
## placeholder unit, then drives the phase HUD. Deployment, multiple units
## and per-phase actions are Phase 2/3 work — this is the Phase 1 "clickable
## prototype" milestone.
extends Node

@onready var ruleset_select: Control = $UI/RulesetSelect
@onready var aos_button: Button = $UI/RulesetSelect/AoSButton
@onready var forty_k_button: Button = $UI/RulesetSelect/FortyKButton
@onready var hud: Control = $UI/HUD
@onready var phase_label: Label = $UI/HUD/PhaseLabel
@onready var next_phase_button: Button = $UI/HUD/NextPhaseButton
@onready var world: Node2D = $World

var turn_manager: TurnManager


func _ready() -> void:
	hud.visible = false
	aos_button.pressed.connect(_start_match.bind(&"aos4"))
	forty_k_button.pressed.connect(_start_match.bind(&"forty_k_11e"))
	next_phase_button.pressed.connect(_on_next_phase_pressed)


func _start_match(ruleset_id: StringName) -> void:
	ruleset_select.visible = false
	hud.visible = true

	RulesetRegistry.set_active_by_id(ruleset_id)
	turn_manager = TurnManager.new(RulesetRegistry.active)
	turn_manager.phase_machine.phase_changed.connect(_on_phase_changed)
	turn_manager.turn_started.connect(_on_turn_started)

	_spawn_placeholder_unit(ruleset_id)
	turn_manager.start_match()


func _spawn_placeholder_unit(ruleset_id: StringName) -> void:
	var board: Node2D = preload("res://scenes/board/Board.tscn").instantiate()
	world.add_child(board)

	var stats_path := "res://data/aos/units/test_order_warriors.tres"
	if ruleset_id == &"forty_k_11e":
		stats_path = "res://data/forty_k/units/test_imperium_squad.tres"
	var stats: UnitStats = load(stats_path)

	var token: UnitToken = preload("res://scenes/unit/UnitToken.tscn").instantiate()
	board.add_child(token)
	token.apply_stats(stats)
	token.position = Vector2(150, 120)


func _on_phase_changed(phase: GamePhase) -> void:
	EventBus.phase_changed.emit(phase)
	phase_label.text = "Player %d — Round %d — %s" % [
		turn_manager.active_player + 1, turn_manager.battle_round, phase.get_phase_name()
	]


func _on_turn_started(active_player: int, battle_round: int) -> void:
	EventBus.turn_started.emit(active_player, battle_round)


func _on_next_phase_pressed() -> void:
	var current_phase: GamePhase = turn_manager.phase_machine.current_phase
	if current_phase:
		current_phase.request_end_phase()
