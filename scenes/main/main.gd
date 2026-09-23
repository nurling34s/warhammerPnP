## Boots a match: lets the player pick a ruleset, runs a simple click-to-
## deploy step for one placeholder unit per side within its zone, then
## starts the phase HUD. During Movement Phase the active player's token
## can be dragged (green/red tint from core/'s can_move_to, committed via
## try_move_unit on release). During Shooting/Combat/Fight Phase, click your
## own not-yet-acted unit, then click an enemy token to declare an attack
## (range/LoS/engagement validated in core/, first ranged/melee weapon on
## the unit is used automatically — a weapon-choice UI is later work).
extends Node

@onready var ruleset_select: Control = $UI/RulesetSelect
@onready var aos_button: Button = $UI/RulesetSelect/AoSButton
@onready var forty_k_button: Button = $UI/RulesetSelect/FortyKButton
@onready var deployment_panel: Control = $UI/DeploymentPanel
@onready var deployment_label: Label = $UI/DeploymentPanel/DeploymentLabel
@onready var hud: Control = $UI/HUD
@onready var phase_label: Label = $UI/HUD/PhaseLabel
@onready var next_phase_button: Button = $UI/HUD/NextPhaseButton
@onready var world: Node2D = $World

var turn_manager: TurnManager
var board: Node2D
var deployment_overlay: DeploymentZoneOverlay
var deployment_manager: DeploymentManager
var current_phase: GamePhase
var attack_resolver: AttackResolver
var tokens: Array[UnitToken] = []
var shoot_selected_attacker: UnitInstance = null
var fight_selected_attacker: UnitInstance = null


func _ready() -> void:
	deployment_panel.visible = false
	hud.visible = false
	aos_button.pressed.connect(_start_match.bind(&"aos4"))
	forty_k_button.pressed.connect(_start_match.bind(&"forty_k_11e"))
	next_phase_button.pressed.connect(_on_next_phase_pressed)


func _start_match(ruleset_id: StringName) -> void:
	ruleset_select.visible = false

	RulesetRegistry.set_active_by_id(ruleset_id)
	turn_manager = TurnManager.new(RulesetRegistry.active)
	turn_manager.phase_machine.phase_changed.connect(_on_phase_changed)
	turn_manager.turn_started.connect(_on_turn_started)
	attack_resolver = AttackResolver.new(RulesetRegistry.active, DiceRoller.new(), turn_manager.match_state.combat_log)

	_setup_board()
	_begin_deployment(ruleset_id)


func _setup_board() -> void:
	board = preload("res://scenes/board/Board.tscn").instantiate()
	world.add_child(board)
	board.clicked.connect(_on_board_clicked)

	deployment_overlay = preload("res://scenes/board/DeploymentZoneOverlay.tscn").instantiate()
	board.add_child(deployment_overlay)

	_spawn_placeholder_terrain()


## One impassable terrain piece in the middle of the table, just to prove
## out blocks_movement end-to-end. Scenario-driven terrain layouts are
## later work.
func _spawn_placeholder_terrain() -> void:
	var piece := TerrainPiece.new()
	piece.terrain_id = &"test_ruins"
	piece.footprint_inches = Rect2(25, 17, 10, 10)
	piece.blocks_movement = true
	turn_manager.match_state.terrain.append(piece)

	var view: TerrainPieceView = preload("res://scenes/board/TerrainPieceView.tscn").instantiate()
	board.add_child(view)
	view.apply_piece(piece)


func _begin_deployment(ruleset_id: StringName) -> void:
	var zone0 := DeploymentZone.new()
	zone0.owner_player = 0
	zone0.rect_inches = Rect2(0, 0, 15, BoardScale.TABLE_HEIGHT_INCHES)

	var zone1 := DeploymentZone.new()
	zone1.owner_player = 1
	zone1.rect_inches = Rect2(BoardScale.TABLE_WIDTH_INCHES - 15, 0, 15, BoardScale.TABLE_HEIGHT_INCHES)

	var zones: Array[DeploymentZone] = [zone0, zone1]
	deployment_overlay.set_zones(zones)

	var stats_paths := {
		0: "res://data/aos/units/test_order_warriors.tres",
		1: "res://data/aos/units/test_chaos_brutes.tres",
	}
	if ruleset_id == &"forty_k_11e":
		stats_paths = {
			0: "res://data/forty_k/units/test_imperium_squad.tres",
			1: "res://data/forty_k/units/test_ork_squad.tres",
		}

	var units: Array[UnitInstance] = []
	for player in stats_paths.keys():
		var stats: UnitStats = load(stats_paths[player])
		units.append(UnitInstance.new(stats, player))

	deployment_manager = DeploymentManager.new(zones, turn_manager.match_state, units)
	deployment_manager.deployment_complete.connect(_on_deployment_complete)

	deployment_panel.visible = true
	_update_deployment_label()


func _update_deployment_label() -> void:
	if deployment_manager.pending_units.is_empty():
		return
	var next_unit: UnitInstance = deployment_manager.pending_units[0]
	deployment_label.text = "Player %d: click inside your zone to deploy %s" % [
		next_unit.owner_player + 1, next_unit.stats.display_name
	]


func _on_board_clicked(position_inches: Vector2) -> void:
	if deployment_manager and not deployment_manager.pending_units.is_empty():
		_handle_deployment_click(position_inches)
	elif current_phase is ShootingPhaseBase:
		_handle_shooting_click(position_inches)
	elif current_phase is FightPhaseBase:
		_handle_fight_click(position_inches)


func _handle_deployment_click(position_inches: Vector2) -> void:
	var unit: UnitInstance = deployment_manager.pending_units[0]
	if deployment_manager.place_unit(unit, position_inches):
		var token: UnitToken = preload("res://scenes/unit/UnitToken.tscn").instantiate()
		board.add_child(token)
		token.apply_instance(unit)
		token.drag_moved.connect(_on_token_drag_moved.bind(token))
		token.drag_ended.connect(_on_token_drag_ended.bind(token))
		tokens.append(token)
		_update_deployment_label()


## Two-click flow: first click picks your own not-yet-shot unit, second
## click picks an enemy token to shoot at with its first ranged weapon.
func _handle_shooting_click(position_inches: Vector2) -> void:
	var clicked_token := _find_token_at(position_inches)
	if not clicked_token:
		return

	if shoot_selected_attacker == null:
		if clicked_token.unit_instance.owner_player == turn_manager.active_player and not clicked_token.unit_instance.has_shot:
			shoot_selected_attacker = clicked_token.unit_instance
		return

	if clicked_token.unit_instance.owner_player != shoot_selected_attacker.owner_player:
		var weapon := _find_ranged_weapon(shoot_selected_attacker.stats)
		if weapon:
			var result: Dictionary = current_phase.declare_shoot(
				shoot_selected_attacker, weapon, clicked_token.unit_instance,
				turn_manager.match_state.terrain, attack_resolver
			)
			if result.ok:
				clicked_token.refresh_label()
	shoot_selected_attacker = null


## Two-click flow: first click picks your own engaged, not-yet-fought unit,
## second click picks an enemy token in engagement range to fight with its
## first melee weapon. Does not enforce the activation queue's chargers-
## first/alternating order — FightPhaseBase.next_to_fight()/activation_queue()
## are available for a stricter UI later.
func _handle_fight_click(position_inches: Vector2) -> void:
	var clicked_token := _find_token_at(position_inches)
	if not clicked_token:
		return

	if fight_selected_attacker == null:
		if clicked_token.unit_instance.owner_player == turn_manager.active_player and not clicked_token.unit_instance.has_fought:
			fight_selected_attacker = clicked_token.unit_instance
		return

	if clicked_token.unit_instance.owner_player != fight_selected_attacker.owner_player:
		var weapon := _find_melee_weapon(fight_selected_attacker.stats)
		if weapon:
			current_phase.declare_pile_in(fight_selected_attacker, clicked_token.unit_instance)
			_find_token_for_instance(fight_selected_attacker).sync_position_from_instance()
			var result: Dictionary = current_phase.declare_fight(fight_selected_attacker, weapon, clicked_token.unit_instance, attack_resolver)
			if result.ok:
				clicked_token.refresh_label()
	fight_selected_attacker = null


func _find_token_for_instance(instance: UnitInstance) -> UnitToken:
	for token in tokens:
		if token.unit_instance == instance:
			return token
	return null


func _find_melee_weapon(stats: UnitStats) -> WeaponProfile:
	for weapon in stats.weapons:
		if weapon.range_inches == 0.0:
			return weapon
	return null


func _find_token_at(position_inches: Vector2) -> UnitToken:
	for token in tokens:
		if token.unit_instance and token.unit_instance.position_inches.distance_to(position_inches) <= 2.0:
			return token
	return null


func _find_ranged_weapon(stats: UnitStats) -> WeaponProfile:
	for weapon in stats.weapons:
		if weapon.range_inches > 0.0:
			return weapon
	return null


func _on_deployment_complete() -> void:
	deployment_panel.visible = false
	hud.visible = true
	turn_manager.start_match()


func _on_token_drag_moved(position_inches: Vector2, token: UnitToken) -> void:
	token.set_drag_feedback(_can_drag_move(token, position_inches))


func _on_token_drag_ended(position_inches: Vector2, token: UnitToken) -> void:
	token.clear_drag_feedback()
	if current_phase is MovementPhaseBase and token.unit_instance.owner_player == turn_manager.active_player:
		current_phase.try_move_unit(token.unit_instance, position_inches, turn_manager.match_state.units)
	token.sync_position_from_instance()


func _can_drag_move(token: UnitToken, position_inches: Vector2) -> bool:
	if not (current_phase is MovementPhaseBase) or token.unit_instance.owner_player != turn_manager.active_player:
		return false
	var result: Dictionary = current_phase.can_move_to(token.unit_instance, position_inches, turn_manager.match_state.units)
	return result.ok


func _on_phase_changed(phase: GamePhase) -> void:
	current_phase = phase
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
