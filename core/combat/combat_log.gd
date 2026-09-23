## Pure data recording of attack outcomes — no UI coupling. AttackResolver
## logs here if given an instance; Phase 4's combat-log panel will read
## `entries`/subscribe to `entry_logged` without needing any AttackResolver
## changes.
class_name CombatLog
extends RefCounted

signal entry_logged(entry: Dictionary)

var entries: Array[Dictionary] = []


func log_attack(attacker: UnitInstance, target: UnitInstance, weapon: WeaponProfile, outcome: AttackOutcome) -> void:
	var entry := {
		"attacker": attacker.stats.display_name,
		"target": target.stats.display_name,
		"weapon": weapon.weapon_name,
		"hits": outcome.to_hit.successes,
		"wounds": outcome.to_wound.successes,
		"failed_saves": outcome.failed_save_count(),
		"models_slain": outcome.models_slain,
	}
	entries.append(entry)
	entry_logged.emit(entry)
