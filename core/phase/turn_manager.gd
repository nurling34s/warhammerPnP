## Owns battle-round count and active-player priority, and drives a
## PhaseStateMachine built fresh from the active ruleset at the start of
## every player's turn. Takes the RulesetProvider directly (rather than
## reaching for the RulesetRegistry autoload) so it stays testable in
## isolation, outside the scene tree.
class_name TurnManager
extends RefCounted

signal turn_started(active_player: int, battle_round: int)

var ruleset: RulesetProvider
var phase_machine: PhaseStateMachine
var match_state: MatchState
var active_player: int = 0
var battle_round: int = 1
var player_count: int = 2


func _init(ruleset_provider: RulesetProvider, players: int = 2, state: MatchState = null) -> void:
	ruleset = ruleset_provider
	player_count = players
	match_state = state if state else MatchState.new()
	phase_machine = PhaseStateMachine.new(self)


func start_match() -> void:
	active_player = 0
	battle_round = 1
	_start_player_turn()


func advance_player_turn() -> void:
	active_player = (active_player + 1) % player_count
	if active_player == 0:
		battle_round += 1
	_start_player_turn()


func _start_player_turn() -> void:
	var phases: Array[GamePhase] = ruleset.build_phase_sequence(self)
	turn_started.emit(active_player, battle_round)
	phase_machine.start(phases)
