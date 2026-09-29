## Read-only, append-only view over CombatLog. Subscribes directly to
## MatchState.combat_log.entry_logged — formatting is chosen per entry "kind"
## (attack / charge / move / message); no changes to core/ are needed for the
## panel to show a new kind, only a new branch here.
class_name CombatLogPanel
extends PanelContainer

@onready var rich_label: RichTextLabel = $RichTextLabel


func connect_log(log: CombatLog) -> void:
	for entry in log.entries:
		_append_entry(entry)
	log.entry_logged.connect(_append_entry)


func _append_entry(entry: Dictionary) -> void:
	match entry.get("kind", "attack"):
		"charge":
			var needed := ""
			if entry.get("distance_needed", 0.0) > 0.0:
				needed = " (needed %.1f\")" % entry.distance_needed
			rich_label.append_text("[b]%s[/b] charges %s: rolled %d\"%s — %s\n" % [
				entry.attacker, entry.target, entry.distance_rolled, needed,
				"[color=green]success[/color]" if entry.success else "[color=red]failed[/color]"
			])
		"move":
			rich_label.append_text("[b]%s[/b] moved %.1f\" (max %.1f\")\n" % [entry.unit, entry.distance, entry.max])
		"message":
			rich_label.append_text("[color=gray]%s[/color]\n" % entry.text)
		_:
			_append_attack(entry)


func _append_attack(entry: Dictionary) -> void:
	if not entry.has("hit_rolls"):
		# Legacy summary-only entry.
		rich_label.append_text("[b]%s[/b] → %s (%s): %d hits, %d wounds, %d failed saves, %d slain\n" % [
			entry.attacker, entry.target, entry.weapon,
			entry.hits, entry.wounds, entry.failed_saves, entry.models_slain
		])
		return

	var rend_note := " (rend %d)" % entry.rend if entry.rend != 0 else ""
	rich_label.append_text("[b]%s[/b] → %s with %s: %d attacks\n" % [
		entry.attacker, entry.target, entry.weapon, entry.attacks
	])
	rich_label.append_text("   Hit %d+ %s → %d\n" % [entry.hit_target, entry.hit_rolls, entry.hits])
	rich_label.append_text("   Wound %d+ %s → %d\n" % [entry.wound_target, entry.wound_rolls, entry.wounds])
	rich_label.append_text("   Save %d+%s %s → %d failed\n" % [entry.save_target, rend_note, entry.save_rolls, entry.failed_saves])
	rich_label.append_text("   %d damage, %d models slain\n" % [entry.damage, entry.models_slain])
