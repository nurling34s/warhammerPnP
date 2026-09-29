## Boots a match: lets the player pick a ruleset, runs a simple click-to-
## deploy step for one placeholder unit per side within its zone, then
## starts the phase HUD. During Movement Phase the active player's token
## can be dragged (green/red tint from core/'s can_move_to, committed via
## try_move_unit on release). During Charge Phase, click your unit then an
## enemy to roll a charge (see _handle_charge_click). During Shooting/Fight Phase, click your
## own not-yet-acted unit, then click an enemy token to declare an attack
## (range/LoS/engagement validated in core/) — if the attacker has more than
## one matching weapon, WeaponChoicePopup asks which one; with exactly one,
## it's used automatically and no popup appears. Objective markers are scored
## every ruleset's last phase of the turn (see ObjectiveScoring); the match
## ends after TurnManager.max_battle_rounds with a winner by victory points,
## shown in MatchEndLabel. Ported to 40k in Phase 5f — both rulesets now share
## this whole UI layer, not just AoS4.
##
## Phase 5e UX: a gold dot over a token means that unit still has a pending
## action this phase (_pending_units_for_current_phase); "Next Phase" asks
## for confirmation if any of the active player's units are still pending;
## "Undo last move" reverts the single most recent successful move, until
## the phase changes or another move is made.
extends Node

@onready var ruleset_select: Control = $UI/RulesetSelect
@onready var aos_button: Button = $UI/RulesetSelect/AoSButton
@onready var forty_k_button: Button = $UI/RulesetSelect/FortyKButton
@onready var deployment_panel: Control = $UI/DeploymentPanel
@onready var deployment_label: Label = $UI/DeploymentPanel/DeploymentLabel
@onready var hud: Control = $UI/HUD
@onready var phase_label: Label = $UI/HUD/PhaseLabel
@onready var next_phase_button: Button = $UI/HUD/NextPhaseButton
@onready var undo_move_button: Button = $UI/HUD/UndoMoveButton
@onready var fall_back_button: Button = $UI/HUD/FallBackButton
@onready var match_end_label: Label = $UI/HUD/MatchEndLabel
@onready var end_phase_confirm_popup: EndPhaseConfirmPopup = $UI/EndPhaseConfirmPopup
@onready var world: Node2D = $World
@onready var roster_panel: RosterPanel = $UI/Sidebar/RosterPanel
@onready var unit_card: UnitCard = $UI/Sidebar/UnitCard
@onready var combat_log_panel: CombatLogPanel = $UI/CombatLogPanel
@onready var weapon_choice_popup: WeaponChoicePopup = $UI/WeaponChoicePopup

var turn_manager: TurnManager
var board: Node2D
var deployment_overlay: DeploymentZoneOverlay
var deployment_manager: DeploymentManager
var current_phase: GamePhase
var attack_resolver: AttackResolver
var tokens: Array[UnitToken] = []
var objective_views: Array[ObjectiveMarkerView] = []
var drag_ruler: DragRuler
var shoot_selected_attacker: UnitInstance = null
var fight_selected_attacker: UnitInstance = null
var charge_selected_attacker: UnitInstance = null
## Shared by charge rolls and Fall Back self-damage.
var dice: DiceRoller = DiceRoller.new()

## Set while WeaponChoicePopup is open, so _on_weapon_chosen() knows which
## attack to actually resolve once the player picks a weapon.
var _pending_attacker: UnitInstance = null
var _pending_target: UnitInstance = null
var _pending_mode: StringName = &""

## Set right after a successful move, so UndoMoveButton can revert exactly
## one action (Phase 5e). Cleared on undo or on any phase change — this is a
## single-action undo, not a stack.
var _last_move: Dictionary = {}


func _ready() -> void:
	deployment_panel.visible = false
	hud.visible = false
	aos_button.pressed.connect(_start_match.bind(&"aos4"))
	forty_k_button.pressed.connect(_start_match.bind(&"forty_k_11e"))
	next_phase_button.pressed.connect(_on_next_phase_pressed)
	undo_move_button.pressed.connect(_on_undo_move_pressed)
	fall_back_button.toggled.connect(_on_fall_back_toggled)
	roster_panel.unit_selected.connect(_on_roster_unit_selected)
	weapon_choice_popup.weapon_chosen.connect(_on_weapon_chosen)
	end_phase_confirm_popup.confirmed.connect(_end_current_phase)


func _start_match(ruleset_id: StringName) -> void:
	ruleset_select.visible = false
	match_end_label.visible = false
	next_phase_button.disabled = false

	RulesetRegistry.set_active_by_id(ruleset_id)
	turn_manager = TurnManager.new(RulesetRegistry.active)
	turn_manager.phase_machine.phase_changed.connect(_on_phase_changed)
	turn_manager.turn_started.connect(_on_turn_started)
	turn_manager.match_ended.connect(_on_match_ended)
	attack_resolver = AttackResolver.new(RulesetRegistry.active, DiceRoller.new(), turn_manager.match_state.combat_log)
	combat_log_panel.connect_log(turn_manager.match_state.combat_log)

	_setup_board()
	_spawn_placeholder_objective()
	_begin_deployment(ruleset_id)


func _setup_board() -> void:
	board = preload("res://scenes/board/Board.tscn").instantiate()
	world.add_child(board)
	board.clicked.connect(_on_board_clicked)

	deployment_overlay = preload("res://scenes/board/DeploymentZoneOverlay.tscn").instantiate()
	board.add_child(deployment_overlay)

	drag_ruler = preload("res://scenes/effects/DragRuler.tscn").instantiate()
	board.add_child(drag_ruler)

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


## Three objectives (Phase 5d) — scored every End Phase (AoS4) / Battle-shock
## Phase (40k, its last phase, same slot) by ObjectiveScoring, shared by both
## rulesets since Phase 5f (each reads its own controlling characteristic:
## AoSUnitStats.control_score or FortyKUnitStats.objective_control). One sits
## just inside each deployment zone (reachable, even controllable, from turn 1
## without needing several movement phases first), one in the middle for a
## contested tug-of-war.
func _spawn_placeholder_objective() -> void:
	var mid_y := BoardScale.TABLE_HEIGHT_INCHES / 2.0
	var positions := [
		Vector2(10.0, mid_y),
		Vector2(BoardScale.TABLE_WIDTH_INCHES / 2.0, mid_y),
		Vector2(BoardScale.TABLE_WIDTH_INCHES - 10.0, mid_y),
	]
	for position_inches in positions:
		var objective := ObjectiveMarker.new()
		objective.position_inches = position_inches
		objective.radius_inches = 6.0
		turn_manager.match_state.objectives.append(objective)

		var view: ObjectiveMarkerView = preload("res://scenes/board/ObjectiveMarkerView.tscn").instantiate()
		board.add_child(view)
		view.apply_objective(objective)
		objective_views.append(view)


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
		0: "res://data/aos/units/stormcast_judicators.tres",
		1: "res://data/aos/units/slaves_to_darkness_warriors.tres",
	}
	if ruleset_id == &"forty_k_11e":
		stats_paths = {
			0: "res://data/forty_k/units/space_marine_intercessors.tres",
			1: "res://data/forty_k/units/ork_boyz.tres",
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
	var inspected_token := _find_token_at(position_inches)
	if inspected_token:
		unit_card.show_unit(inspected_token.unit_instance)

	if deployment_manager and not deployment_manager.pending_units.is_empty():
		_handle_deployment_click(position_inches)
	elif current_phase is MovementPhaseBase:
		_handle_movement_click(position_inches)
	elif current_phase is ShootingPhaseBase:
		_handle_shooting_click(position_inches)
	elif current_phase is ChargePhaseBase:
		_handle_charge_click(position_inches)
	elif current_phase is FightPhaseBase:
		_handle_fight_click(position_inches)


func _on_fall_back_toggled(pressed: bool) -> void:
	if pressed:
		_log("Fall Back: click one of your units that is in combat")


## Only acts while the Fall Back button is toggled on: declares the clicked
## unit as falling back (AoS4 also rolls D3 self-damage in core/), after
## which it is dragged out of engagement range like any other move.
func _handle_movement_click(position_inches: Vector2) -> void:
	if not fall_back_button.button_pressed:
		return
	var clicked_token := _find_token_at(position_inches)
	if not clicked_token:
		return

	fall_back_button.button_pressed = false
	var unit := clicked_token.unit_instance
	var unit_name := unit.stats.display_name
	if unit.owner_player != turn_manager.active_player:
		_log("Fall Back: select one of your own units")
	elif unit.has_moved:
		_log("%s has already moved this phase" % unit_name)
	elif unit.has_fallen_back:
		_log("%s is already falling back" % unit_name)
	elif not turn_manager.ruleset.is_in_engagement_range(unit, turn_manager.match_state.units):
		_log("%s isn't in combat, so it has no need to fall back" % unit_name)
	else:
		var wounds_before := _total_wounds(unit)
		current_phase.declare_fall_back(unit, dice)
		var damage := wounds_before - _total_wounds(unit)
		var note := " and takes %d damage" % damage if damage > 0 else ""
		if unit.is_destroyed:
			_log("%s falls back%s and is destroyed" % [unit_name, note])
		else:
			_log("%s falls back%s — drag it out of combat (it can't shoot or charge this turn)" % [unit_name, note])
		clicked_token.refresh_label()
		_last_move = {}
		undo_move_button.visible = false
		_refresh_roster()
		_update_action_indicators()


func _total_wounds(unit: UnitInstance) -> int:
	var total := 0
	for wounds in unit.model_wounds_remaining:
		total += wounds
	return total


func _handle_deployment_click(position_inches: Vector2) -> void:
	var unit: UnitInstance = deployment_manager.pending_units[0]
	if deployment_manager.place_unit(unit, position_inches):
		var token: UnitToken = preload("res://scenes/unit/UnitToken.tscn").instantiate()
		board.add_child(token)
		token.apply_instance(unit)
		token.drag_moved.connect(_on_token_drag_moved)
		token.drag_ended.connect(_on_token_drag_ended)
		tokens.append(token)
		_update_deployment_label()
		_refresh_roster()


## Two-click flow: first click picks your own not-yet-shot unit, second
## click picks an enemy token to shoot at. If the attacker has more than one
## ranged weapon, WeaponChoicePopup asks which one before resolving.
func _handle_shooting_click(position_inches: Vector2) -> void:
	var clicked_token := _find_token_at(position_inches)
	if not clicked_token:
		return

	if shoot_selected_attacker == null:
		var candidate := clicked_token.unit_instance
		if candidate.owner_player != turn_manager.active_player:
			_log("Select one of your own units first")
		elif candidate.has_shot:
			_log("%s has already shot this phase" % candidate.stats.display_name)
		else:
			shoot_selected_attacker = candidate
			_highlight_selected(candidate)
			_log("%s selected — click an enemy unit to shoot" % candidate.stats.display_name)
		return

	var attacker := shoot_selected_attacker
	shoot_selected_attacker = null
	_highlight_selected(null)
	if clicked_token.unit_instance.owner_player == attacker.owner_player:
		_log("Shot cancelled — pick an enemy unit as the target")
		return
	var weapons := _find_ranged_weapons(attacker.stats)
	if weapons.is_empty():
		_log("%s has no ranged weapons" % attacker.stats.display_name)
		return
	_resolve_or_choose_weapon(weapons, attacker, clicked_token.unit_instance, &"shoot")


## Two-click flow: first click picks your own unit that hasn't attempted a
## charge yet, second click picks an enemy token to charge. The 2D6" roll and
## resulting move happen in core/ (ChargePhaseBase.declare_charge); every
## roll — success or fail — is written to the combat log.
func _handle_charge_click(position_inches: Vector2) -> void:
	var clicked_token := _find_token_at(position_inches)
	if not clicked_token:
		return

	if charge_selected_attacker == null:
		var candidate := clicked_token.unit_instance
		if candidate.owner_player != turn_manager.active_player:
			_log("Select one of your own units first")
		elif candidate.has_attempted_charge:
			_log("%s has already attempted a charge" % candidate.stats.display_name)
		else:
			charge_selected_attacker = candidate
			_highlight_selected(candidate)
			_log("%s selected — click an enemy unit to charge" % candidate.stats.display_name)
		return

	var attacker := charge_selected_attacker
	var target := clicked_token.unit_instance
	charge_selected_attacker = null
	_highlight_selected(null)
	if target.owner_player == attacker.owner_player:
		_log("Charge cancelled — pick an enemy unit as the target")
		return

	var result: Dictionary = current_phase.declare_charge(attacker, target, turn_manager.match_state.units, dice)
	if result.distance_rolled > 0:
		turn_manager.match_state.combat_log.log_charge(
			attacker, target, result.distance_rolled, result.ok, result.distance_needed
		)
	elif not result.ok:
		_log("%s can't charge %s: %s" % [attacker.stats.display_name, target.stats.display_name, _reason_text(result.reason)])
	_find_token_for_instance(attacker).sync_position_from_instance()
	_refresh_roster()
	_update_action_indicators()


## Two-click flow: first click picks a unit from FightPhaseBase.
## eligible_units() (either player's — activation order is enforced in
## core/), second click picks an enemy token in engagement range to fight —
## with a weapon choice if the attacker has more than one melee weapon.
func _handle_fight_click(position_inches: Vector2) -> void:
	var clicked_token := _find_token_at(position_inches)
	if not clicked_token:
		return

	if fight_selected_attacker == null:
		var candidate := clicked_token.unit_instance
		var eligible: Array[UnitInstance] = current_phase.eligible_units()
		if candidate.has_fought:
			_log("%s has already fought this phase" % candidate.stats.display_name)
		elif not current_phase.pending_units().has(candidate):
			_log("%s isn't in combat" % candidate.stats.display_name)
		elif not eligible.has(candidate):
			_log("Not %s's turn to fight — Player %d activates next" % [
				candidate.stats.display_name, eligible[0].owner_player + 1
			])
		else:
			fight_selected_attacker = candidate
			_highlight_selected(candidate)
			_log("%s selected — click an enemy unit in engagement range to fight" % candidate.stats.display_name)
		return

	var attacker := fight_selected_attacker
	fight_selected_attacker = null
	_highlight_selected(null)
	if clicked_token.unit_instance.owner_player == attacker.owner_player:
		_log("Fight cancelled — pick an enemy unit as the target")
		return
	var weapons := _find_melee_weapons(attacker.stats)
	if weapons.is_empty():
		_log("%s has no melee weapons" % attacker.stats.display_name)
		return
	_resolve_or_choose_weapon(weapons, attacker, clicked_token.unit_instance, &"fight")


## Resolves the attack immediately when there's only one matching weapon
## (the common case); otherwise opens WeaponChoicePopup and defers to
## _on_weapon_chosen().
func _resolve_or_choose_weapon(weapons: Array[WeaponProfile], attacker: UnitInstance, target: UnitInstance, mode: StringName) -> void:
	if weapons.is_empty():
		return
	if weapons.size() == 1:
		_execute_attack(weapons[0], attacker, target, mode)
		return

	_pending_attacker = attacker
	_pending_target = target
	_pending_mode = mode
	weapon_choice_popup.show_choices(weapons)


func _on_weapon_chosen(weapon: WeaponProfile) -> void:
	if _pending_attacker == null:
		return
	_execute_attack(weapon, _pending_attacker, _pending_target, _pending_mode)
	_pending_attacker = null
	_pending_target = null
	_pending_mode = &""


func _execute_attack(weapon: WeaponProfile, attacker: UnitInstance, target: UnitInstance, mode: StringName) -> void:
	var result: Dictionary
	if mode == &"shoot":
		result = current_phase.declare_shoot(attacker, weapon, target, turn_manager.match_state.terrain, attack_resolver)
	else:
		# Only pile in when the fight is actually allowed, so a refused fight
		# never moves the unit.
		if current_phase.can_fight(attacker, target).ok:
			var position_before := attacker.position_inches
			current_phase.declare_pile_in(attacker, target)
			var moved := position_before.distance_to(attacker.position_inches)
			if moved > 0.05:
				_log("%s piles in %.1f\"" % [attacker.stats.display_name, moved])
			_find_token_for_instance(attacker).sync_position_from_instance()
		result = current_phase.declare_fight(attacker, weapon, target, attack_resolver)

	if result.ok:
		_find_token_for_instance(target).refresh_label()
		_refresh_roster()
		_update_action_indicators()
	else:
		var detail := ""
		if result.reason == "out_of_range":
			detail = " (%.1f\" away, weapon range %.0f\")" % [attacker.nearest_edge_distance_to(target), weapon.range_inches]
		elif result.reason == "out_of_engagement_range":
			detail = " (%.1f\" away)" % attacker.nearest_edge_distance_to(target)
		_log("%s can't %s %s with %s: %s%s" % [
			attacker.stats.display_name, "shoot" if mode == &"shoot" else "fight",
			target.stats.display_name, weapon.weapon_name, _reason_text(result.reason), detail
		])


const REASON_TEXT := {
	"out_of_range": "target out of range",
	"no_line_of_sight": "no line of sight",
	"already_shot": "already shot this phase",
	"already_fought": "already fought this phase",
	"out_of_engagement_range": "target not in engagement range",
	"already_moved": "already moved this phase",
	"exceeds_move": "farther than its Move allows",
	"blocked_by_terrain": "blocked by terrain",
	"engaged_must_fall_back": "engaged in combat, must fall back",
	"normal_move_cannot_approach_within_engagement_range": "a normal move can't end in engagement range of an enemy",
	"invalid_target": "invalid target",
	"already_attempted_charge": "already attempted a charge this phase",
	"cannot_charge_after_falling_back": "can't charge after falling back",
	"already_engaged": "already in engagement range",
	"not_engaged": "not in engagement range",
	"not_this_units_turn_to_fight": "it's not this unit's turn to fight",
	"cannot_shoot_after_falling_back": "can't shoot after falling back",
	"fall_back_must_end_outside_engagement": "a fall back must end outside engagement range",
}


func _reason_text(reason: String) -> String:
	return REASON_TEXT.get(reason, reason)


func _log(text: String) -> void:
	turn_manager.match_state.combat_log.log_message(text)


## Tints the chosen attacker gold; pass null to clear every highlight.
func _highlight_selected(unit: UnitInstance) -> void:
	for token in tokens:
		if unit != null and token.unit_instance == unit:
			token.set_selected(true)
		else:
			token.set_selected(false)


func _find_token_for_instance(instance: UnitInstance) -> UnitToken:
	for token in tokens:
		if token.unit_instance == instance:
			return token
	return null


func _find_melee_weapons(stats: UnitStats) -> Array[WeaponProfile]:
	var weapons: Array[WeaponProfile] = []
	for weapon in stats.weapons:
		if weapon.range_inches == 0.0:
			weapons.append(weapon)
	return weapons


func _find_token_at(position_inches: Vector2) -> UnitToken:
	for token in tokens:
		if token.unit_instance and token.unit_instance.position_inches.distance_to(position_inches) <= 2.0:
			return token
	return null


func _find_ranged_weapons(stats: UnitStats) -> Array[WeaponProfile]:
	var weapons: Array[WeaponProfile] = []
	for weapon in stats.weapons:
		if weapon.range_inches > 0.0:
			weapons.append(weapon)
	return weapons


func _on_deployment_complete() -> void:
	deployment_panel.visible = false
	hud.visible = true
	turn_manager.start_match()


func _on_token_drag_moved(token: UnitToken, position_inches: Vector2) -> void:
	var valid := _can_drag_move(token, position_inches)
	token.set_drag_feedback(valid)
	if current_phase is MovementPhaseBase and token.unit_instance.owner_player == turn_manager.active_player:
		drag_ruler.show_drag(
			token.unit_instance.position_inches, position_inches,
			token.unit_instance.remaining_move_inches(), valid
		)


func _on_token_drag_ended(token: UnitToken, position_inches: Vector2) -> void:
	token.clear_drag_feedback()
	drag_ruler.hide_drag()
	if current_phase is MovementPhaseBase and token.unit_instance.owner_player == turn_manager.active_player:
		var unit := token.unit_instance
		var position_before := unit.position_inches
		if position_inches.distance_to(position_before) < 0.5:
			token.sync_position_from_instance()  # a click, not a drag — never a move attempt
			return
		var had_moved_before := unit.has_moved
		var result: Dictionary = current_phase.try_move_unit(unit, position_inches, turn_manager.match_state.units)
		if result.ok:
			_last_move = {"unit": unit, "from": position_before, "had_moved": had_moved_before}
			undo_move_button.visible = true
			turn_manager.match_state.combat_log.log_move(
				unit, position_before.distance_to(unit.position_inches), unit.remaining_move_inches()
			)
		else:
			_log("%s can't move there: %s" % [unit.stats.display_name, _reason_text(result.reason)])
		_update_action_indicators()
	token.sync_position_from_instance()


func _can_drag_move(token: UnitToken, position_inches: Vector2) -> bool:
	if not (current_phase is MovementPhaseBase) or token.unit_instance.owner_player != turn_manager.active_player:
		return false
	var result: Dictionary = current_phase.can_move_to(token.unit_instance, position_inches, turn_manager.match_state.units)
	return result.ok


func _on_phase_changed(phase: GamePhase) -> void:
	current_phase = phase
	EventBus.phase_changed.emit(phase)
	var vp := turn_manager.match_state.victory_points
	var vp_text := " — VP %d-%d" % [vp[0], vp[1]] if vp.size() >= 2 else ""
	phase_label.text = "Player %d — Round %d — %s%s" % [
		turn_manager.active_player + 1, turn_manager.battle_round, phase.get_phase_name(), vp_text
	]
	for view in objective_views:
		view.apply_objective(view.objective)  # re-draw with this phase's controlled_by
	shoot_selected_attacker = null
	fight_selected_attacker = null
	charge_selected_attacker = null
	_highlight_selected(null)
	_last_move = {}
	undo_move_button.visible = false
	fall_back_button.button_pressed = false
	fall_back_button.visible = phase is MovementPhaseBase
	_log("— Player %d, round %d: %s —" % [turn_manager.active_player + 1, turn_manager.battle_round, phase.get_phase_name()])
	_update_action_indicators()
	_refresh_roster()


## Units of the active player that still have a pending action in the
## current phase — drives both the "who can act" indicator on the board and
## the end-of-phase confirmation (Phase 5e). Empty for phases with no
## per-unit action yet wired up (Hero/Charge placeholders).
func _pending_units_for_current_phase() -> Array[UnitInstance]:
	if current_phase is ChargePhaseBase:
		return turn_manager.match_state.units_for_player(turn_manager.active_player).filter(
			func(u: UnitInstance): return (
				not u.has_attempted_charge and not u.has_fallen_back
				and not turn_manager.ruleset.is_in_engagement_range(u, turn_manager.match_state.units)
			)
		)
	if current_phase is FightPhaseBase:
		return current_phase.pending_units()
	if current_phase is ShootingPhaseBase:
		return turn_manager.match_state.units_for_player(turn_manager.active_player).filter(
			func(u: UnitInstance): return (
				not u.has_shot and not u.has_fallen_back and not _find_ranged_weapons(u.stats).is_empty()
			)
		)
	if current_phase is MovementPhaseBase:
		return turn_manager.match_state.units_for_player(turn_manager.active_player).filter(
			func(u: UnitInstance): return not u.has_moved
		)
	return []


## In the Fight phase only the units whose turn it is to activate get the dot;
## everywhere else it marks every unit with an action pending.
func _update_action_indicators() -> void:
	var pending: Array[UnitInstance] = current_phase.eligible_units() if current_phase is FightPhaseBase else _pending_units_for_current_phase()
	for token in tokens:
		token.set_can_act_indicator(pending.has(token.unit_instance))


func _on_undo_move_pressed() -> void:
	if _last_move.is_empty():
		return
	var unit: UnitInstance = _last_move.unit
	unit.position_inches = _last_move.from
	unit.has_moved = _last_move.had_moved
	var token := _find_token_for_instance(unit)
	if token:
		token.sync_position_from_instance()
	_log("%s's move undone" % unit.stats.display_name)
	_last_move = {}
	undo_move_button.visible = false
	_update_action_indicators()


func _on_match_ended(winner: int) -> void:
	var vp := turn_manager.match_state.victory_points
	var text: String
	if winner == -1:
		text = "Draw — VP %d-%d" % [vp[0], vp[1]]
	else:
		text = "Player %d wins — VP %d-%d" % [winner + 1, vp[0], vp[1]]
	match_end_label.text = text
	match_end_label.visible = true
	next_phase_button.disabled = true


func _on_turn_started(active_player: int, battle_round: int) -> void:
	EventBus.turn_started.emit(active_player, battle_round)
	_refresh_roster()


func _refresh_roster() -> void:
	roster_panel.refresh(turn_manager.match_state.units_for_player(turn_manager.active_player))


## Roster selection is informational only — it highlights the token and
## shows its card, but never picks a shooting/fight target (that stays a
## click on the board, per the existing two-click flow above).
func _on_roster_unit_selected(unit: UnitInstance) -> void:
	unit_card.show_unit(unit)
	var token := _find_token_for_instance(unit)
	if token:
		token.set_drag_feedback(true)
		await get_tree().create_timer(0.3).timeout
		token.clear_drag_feedback()


## Ends the phase immediately, unless some of the active player's units
## still have a pending action — then confirms first (Phase 5e), so a
## forgotten shot/fight/move isn't skipped by an accidental click.
func _on_next_phase_pressed() -> void:
	var pending := _pending_units_for_current_phase()
	if pending.is_empty():
		_end_current_phase()
	else:
		end_phase_confirm_popup.show_with_pending_count(pending.size())


func _end_current_phase() -> void:
	var phase: GamePhase = turn_manager.phase_machine.current_phase
	if phase:
		phase.request_end_phase()
