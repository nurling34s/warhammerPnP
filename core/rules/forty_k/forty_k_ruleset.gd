## Warhammer 40,000 11th-edition ruleset. Phase order per turn: Command,
## Movement, Shooting, Charge, Fight, Battle-shock (exact placement/wording of
## the battle-shock step should be verified against the current core
## rulebook before real army data is entered — see aos_40k.md plan notes).
##
## Only phase sequencing is implemented so far; combat math, charge rolls,
## battle-shock and coherency are Phase 2/3 work (see RulesetProvider).
class_name FortyKRuleset
extends RulesetProvider


func get_id() -> StringName:
	return &"forty_k_11e"


func build_phase_sequence(turn_manager: TurnManager) -> Array[GamePhase]:
	return [
		NamedPlaceholderPhase.new(turn_manager, &"Command Phase"),
		FortyKMovementPhase.new(turn_manager),
		FortyKShootingPhase.new(turn_manager),
		NamedPlaceholderPhase.new(turn_manager, &"Charge Phase"),
		NamedPlaceholderPhase.new(turn_manager, &"Fight Phase"),
		NamedPlaceholderPhase.new(turn_manager, &"Battle-shock Phase"),
	]


func get_unit_stats_script() -> Script:
	return FortyKUnitStats


## 40k 11th ed engagement range is 1" horizontally (round/placeholder figure;
## the real rule also has a vertical component for multi-level terrain,
## deferred until per-model positions exist — verify against the current
## core rulebook before real army data is entered).
func get_engagement_range_inches() -> float:
	return 1.0


## 2D6" charge roll. End-of-charge/terrain resolution is later work.
func roll_charge_distance(_unit: UnitInstance, dice: DiceRoller) -> int:
	var rolls := dice.roll(2, 6)
	return rolls[0] + rolls[1]


func is_in_engagement_range(unit: UnitInstance, all_units: Array) -> bool:
	var range_inches := get_engagement_range_inches()
	for other in all_units:
		if other == unit or other.owner_player == unit.owner_player or other.is_destroyed:
			continue
		if unit.position_inches.distance_to(other.position_inches) <= range_inches:
			return true
	return false


## To-hit against the weapon's to_hit_stat (a WS/BS override if set on the
## weapon; real datasheets would fall back to the attacker's own
## weapon_skill/ballistic_skill, deferred until weapon data needs it).
func resolve_to_hit(_attacker, weapon: WeaponProfile, _target, ctx: Dictionary, dice: DiceRoller) -> RollResult:
	var chain := ModifierChain.new()
	chain.flat_modifier = int(ctx.get("to_hit_modifier", 0))
	var count: int = int(ctx.get("attack_count", 1))
	return chain.apply(dice, weapon.to_hit_stat, count)


## Strength vs Toughness wound table (modern-edition convention):
## S >= 2T -> 2+, S > T -> 3+, S == T -> 4+, S*2 <= T -> 6+, else 5+.
## Placeholder breakpoints — verify against the current 11th ed core
## rulebook before real army data is entered.
func resolve_to_wound(weapon: WeaponProfile, target, hits: RollResult, _ctx: Dictionary, dice: DiceRoller) -> RollResult:
	var strength: int = int(weapon.strength_or_damage)
	var toughness: int = target.stats.toughness
	var chain := ModifierChain.new()
	return chain.apply(dice, _wound_target(strength, toughness), hits.successes)


func _wound_target(strength: int, toughness: int) -> int:
	if strength >= toughness * 2:
		return 2
	if strength > toughness:
		return 3
	if strength == toughness:
		return 4
	if strength * 2 <= toughness:
		return 6
	return 5


## Armor save worsened by AP; a separate Invulnerable save (if any) is never
## modified by AP. The defender uses whichever save has the better (lower)
## target number. `ap_or_rend` is stored signed (e.g. -1 for "AP -1", matching
## the existing weapon data) so subtracting it raises the target number.
func resolve_save(target, weapon: WeaponProfile, wounds: RollResult, _ctx: Dictionary, dice: DiceRoller) -> RollResult:
	var stats: FortyKUnitStats = target.stats
	var armor_target: int = clampi(stats.save - weapon.ap_or_rend, 2, 7)
	var save_target: int = armor_target
	if stats.invulnerable_save > 0 and stats.invulnerable_save < armor_target:
		save_target = stats.invulnerable_save

	var chain := ModifierChain.new()
	return chain.apply(dice, save_target, wounds.successes)


## Rolls each failed save's Damage characteristic and applies it to the
## target, one model at a time (closest-model-first degrades to "always the
## front of the queue" while units are single points — see UnitInstance).
func allocate_wounds(unit: UnitInstance, damage_events: Array, dice: DiceRoller) -> Array:
	var results: Array = []
	for event in damage_events:
		var weapon: WeaponProfile = event.source_weapon
		var dmg: int = DiceNotation.roll(weapon.damage, dice)
		var leftover: int = unit.apply_damage_to_next_model(dmg)
		results.append({"damage_applied": dmg - leftover})
	return results
