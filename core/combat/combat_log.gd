## Pure data recording of what happens in a match — no UI coupling.
## AttackResolver logs attacks here; the scene layer logs moves, charges and
## plain messages (phase headers, refused actions). Every entry carries a
## "kind" ("attack", "charge", "move" or "message") so the combat-log panel
## knows how to format it.
class_name CombatLog
extends RefCounted

signal entry_logged(entry: Dictionary)

var entries: Array[Dictionary] = []


func log_attack(attacker: UnitInstance, target: UnitInstance, weapon: WeaponProfile, outcome: AttackOutcome) -> void:
	var damage := 0
	for result in outcome.allocation:
		damage += int(result.get("damage_applied", 0))
	_add({
		"kind": "attack",
		"attacker": attacker.stats.display_name,
		"target": target.stats.display_name,
		"weapon": weapon.weapon_name,
		"attacks": outcome.to_hit.raw_rolls.size(),
		"hit_target": outcome.to_hit.target_number,
		"hit_rolls": outcome.to_hit.modified_rolls.duplicate(),
		"wound_target": outcome.to_wound.target_number,
		"wound_rolls": outcome.to_wound.modified_rolls.duplicate(),
		"save_target": outcome.save.target_number,
		"save_rolls": outcome.save.modified_rolls.duplicate(),
		"rend": weapon.ap_or_rend,
		"damage": damage,
		"hits": outcome.to_hit.successes,
		"wounds": outcome.to_wound.successes,
		"failed_saves": outcome.failed_save_count(),
		"models_slain": outcome.models_slain,
	})


func log_charge(unit: UnitInstance, target: UnitInstance, distance_rolled: int, success: bool, distance_needed: float = 0.0) -> void:
	_add({
		"kind": "charge",
		"attacker": unit.stats.display_name,
		"target": target.stats.display_name,
		"distance_rolled": distance_rolled,
		"distance_needed": distance_needed,
		"success": success,
	})


func log_move(unit: UnitInstance, distance: float, max_distance: float) -> void:
	_add({
		"kind": "move",
		"unit": unit.stats.display_name,
		"distance": distance,
		"max": max_distance,
	})


func log_message(text: String) -> void:
	_add({"kind": "message", "text": text})


func _add(entry: Dictionary) -> void:
	entries.append(entry)
	entry_logged.emit(entry)
