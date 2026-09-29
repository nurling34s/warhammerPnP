## Read-only stat card for a single UnitInstance. Reads UnitStats (and its
## AoSUnitStats/FortyKUnitStats subclass, checked with `is` — the one place
## a ruleset branch belongs in this UI layer, since it's purely about which
## fields to display) plus WeaponProfile data. Never mutates core/ state.
class_name UnitCard
extends PanelContainer

@onready var content: RichTextLabel = $Layout/Content
@onready var close_button: Button = $Layout/Header/CloseButton


func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)


func _on_close_pressed() -> void:
	visible = false


func show_unit(unit: UnitInstance) -> void:
	visible = true
	var stats: UnitStats = unit.stats
	var lines: Array = []

	lines.append("[b]%s[/b] (%s)" % [stats.display_name, stats.faction])
	lines.append("Move %.0f\"  Health %d  Save %d+" % [stats.move_inches, stats.health_per_model, stats.save])
	lines.append("Models: %d/%d   Points: %d" % [unit.models_alive, stats.models_per_unit, stats.points_cost])

	if stats is AoSUnitStats:
		var aos: AoSUnitStats = stats
		lines.append("Bravery %d   Control %d   Rend %d" % [aos.bravery, aos.control_score, aos.rend_default])
		if aos.ward_save > 0:
			lines.append("Ward %d+" % aos.ward_save)
	elif stats is FortyKUnitStats:
		var fk: FortyKUnitStats = stats
		lines.append("Toughness %d   Leadership %d   WS %d+   BS %d+" % [fk.toughness, fk.leadership, fk.weapon_skill, fk.ballistic_skill])
		if fk.invulnerable_save > 0:
			lines.append("Invulnerable %d++" % fk.invulnerable_save)
		lines.append("OC %d" % fk.objective_control)

	lines.append("")
	lines.append("[b]Weapons[/b]")
	for weapon in stats.weapons:
		lines.append(_weapon_line(weapon))

	content.text = "\n".join(lines)
	tooltip_text = _words_text(stats.keywords)


func _weapon_line(weapon: WeaponProfile) -> String:
	var range_text: String = "Melee" if weapon.range_inches == 0.0 else "%.0f\"" % weapon.range_inches
	var rules_text: String = _words_text(weapon.special_rules)
	if rules_text.is_empty():
		rules_text = "-"
	return "%s: Range %s, A %s, Hit %d+, S/D %s, AP/Rend %d, Rules: %s" % [
		weapon.weapon_name, range_text, weapon.attacks, weapon.to_hit_stat,
		weapon.strength_or_damage, weapon.ap_or_rend, rules_text
	]


func _words_text(words: Array) -> String:
	var strings: Array = []
	for word in words:
		strings.append(String(word))
	return ", ".join(strings)
