## Global signal hub. UI subscribes here instead of reaching into core/
## objects directly, keeping scenes reactive to core/ state rather than
## coupled to it.
extends Node

signal phase_changed(phase: GamePhase)
signal turn_started(active_player: int, battle_round: int)
