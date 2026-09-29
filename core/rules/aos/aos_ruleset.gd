## Age of Sigmar 4th-edition ruleset. Phase order per turn: Hero, Movement,
## Shooting, Charge, Combat, End. AoS4 has no Battleshock phase or mechanic
## at all (see warhammer_age_of_sigmar_4.md section 1) — End Phase is where
## objective control gets scored instead (Phase 5d, not built yet).
class_name AoSRuleset
extends RulesetProvider


func get_id() -> StringName:
	return &"aos4"


func build_phase_sequence(turn_manager: TurnManager) -> Array[GamePhase]:
	return [
		NamedPlaceholderPhase.new(turn_manager, &"Hero Phase"),
		AoSMovementPhase.new(turn_manager),
		AoSShootingPhase.new(turn_manager),
		AoSChargePhase.new(turn_manager),
		AoSFightPhase.new(turn_manager),
		AoSEndPhase.new(turn_manager),
	]


func get_unit_stats_script() -> Script:
	return AoSUnitStats


## AoS4 standardized melee/engagement range to 3" (warhammer_age_of_sigmar_4.md
## section 1, "Единый радиус ближнего боя").
func get_engagement_range_inches() -> float:
	return 3.0


## 2D6" charge roll. End-of-charge/terrain resolution is later work.
func roll_charge_distance(_unit: UnitInstance, dice: DiceRoller) -> int:
	var rolls := dice.roll(2, 6)
	return rolls[0] + rolls[1]


## Uses nearest-model-to-nearest-model distance (unit.model_positions), not
## the unit's anchor point — see UnitInstance.model_positions doc.
func is_in_engagement_range(unit: UnitInstance, all_units: Array) -> bool:
	var range_inches := get_engagement_range_inches()
	for other in all_units:
		if other == unit or other.owner_player == unit.owner_player or other.is_destroyed:
			continue
		if unit.nearest_edge_distance_to(other) <= range_inches:
			return true
	return false


## Real per-model coherency check (see UnitInstance.is_coherent) rather than
## the RulesetProvider stub.
func check_unit_coherency(unit: UnitInstance) -> bool:
	return unit.is_coherent(UnitInstance.MODEL_SPACING_INCHES)


## Flat roll against the weapon's to_hit_stat (its Hit characteristic).
##
## Not yet implemented: warhammer_age_of_sigmar_4.md section 2/4 describes
## Crit effects (Mortal / Auto-wound / 2 Hits) triggered by an unmodified 6
## on this roll. Deliberately deferred — this is a new weapon-abilities
## feature, not a correction of existing behavior, so it's tracked
## separately rather than folded into this rules-compliance pass.
func resolve_to_hit(_attacker, weapon: WeaponProfile, _target, ctx: Dictionary, dice: DiceRoller) -> RollResult:
	var chain := ModifierChain.new()
	chain.flat_modifier = int(ctx.get("to_hit_modifier", 0))
	var count: int = int(ctx.get("attack_count", 1))
	return chain.apply(dice, weapon.to_hit_stat, count)


## AoS4 *does* have a separate Wound roll (warhammer_age_of_sigmar_4.md
## section 2/4: "Wound Roll: Успешные попадания бросаются снова") — this
## replaces an earlier, incorrect pass-through that assumed the AoS3 combat
## sequence (no separate to-wound step). One D6 per successful Hit, against
## the weapon's wound_stat.
func resolve_to_wound(weapon: WeaponProfile, _target, hits: RollResult, _ctx: Dictionary, dice: DiceRoller) -> RollResult:
	var chain := ModifierChain.new()
	return chain.apply(dice, weapon.wound_stat, hits.successes)


## Armor save modified by Rend (-ap_or_rend), plus a second, unmodified Ward
## save pass over whatever the armor save didn't stop, if the unit has one.
## The returned RollResult's `successes` is the combined total saved
## (armor + ward) — allocate_wounds treats `wounds.successes - save.successes`
## as the number of failed saves needing damage.
func resolve_save(target, weapon: WeaponProfile, wounds: RollResult, _ctx: Dictionary, dice: DiceRoller) -> RollResult:
	var stats: AoSUnitStats = target.stats
	var armor_chain := ModifierChain.new()
	# ap_or_rend is stored signed like 40k's AP (data uses e.g. -1 for "Rend -1"),
	# so adding it to the roll makes the save harder. Was negated by mistake.
	armor_chain.flat_modifier = weapon.ap_or_rend
	var armor_result: RollResult = armor_chain.apply(dice, stats.save, wounds.successes)

	var total_saved: int = armor_result.successes
	if stats.ward_save > 0:
		var failed_armor: int = wounds.successes - armor_result.successes
		if failed_armor > 0:
			var ward_chain := ModifierChain.new()
			var ward_result: RollResult = ward_chain.apply(dice, stats.ward_save, failed_armor)
			total_saved += ward_result.successes

	var combined := RollResult.new()
	combined.target_number = stats.save
	combined.successes = total_saved
	combined.raw_rolls = armor_result.raw_rolls
	combined.final_rolls = armor_result.final_rolls
	combined.modified_rolls = armor_result.modified_rolls
	combined.critical_successes = armor_result.critical_successes
	return combined


## Intentionally not overridden: AoS4 has no Battleshock at all (see
## warhammer_age_of_sigmar_4.md section 1, "Отмена Battleshock" — this
## replaces an earlier, AoS3-based Bravery-test implementation that used to
## live here). Nothing calls RulesetProvider.resolve_battleshock() for AoS4
## any more; only FortyKRuleset still overrides it.


## Rolls each failed save's Damage characteristic (weapon.strength_or_damage
## is AoS4's Damage char) and applies it to the target, one model at a time.
func allocate_wounds(unit: UnitInstance, damage_events: Array, dice: DiceRoller) -> Array:
	var results: Array = []
	for event in damage_events:
		var weapon: WeaponProfile = event.source_weapon
		var dmg: int = DiceNotation.roll(weapon.strength_or_damage, dice)
		var leftover: int = unit.apply_damage_to_next_model(dmg)
		results.append({"damage_applied": dmg - leftover})
	return results
