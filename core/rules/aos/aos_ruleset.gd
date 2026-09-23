## Age of Sigmar 4th-edition ruleset. Phase order per turn: Hero, Movement,
## Shooting, Charge, Combat, End (Battleshock resolves inside End Phase for
## both players, per AoS4 — it is not a separate phase, unlike AoS3).
##
## Only phase sequencing is implemented so far; combat math, charge rolls,
## battleshock and coherency are Phase 2/3 work (see RulesetProvider).
class_name AoSRuleset
extends RulesetProvider


func get_id() -> StringName:
	return &"aos4"


func build_phase_sequence(turn_manager: TurnManager) -> Array[GamePhase]:
	return [
		NamedPlaceholderPhase.new(turn_manager, &"Hero Phase"),
		AoSMovementPhase.new(turn_manager),
		AoSShootingPhase.new(turn_manager),
		NamedPlaceholderPhase.new(turn_manager, &"Charge Phase"),
		AoSFightPhase.new(turn_manager),
		AoSEndPhase.new(turn_manager),
	]


func get_unit_stats_script() -> Script:
	return AoSUnitStats


## AoS4 engagement range is 3" horizontally from the unit's models
## (round/placeholder figure — verify against the current core rulebook).
func get_engagement_range_inches() -> float:
	return 3.0


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


## AoS4 has no separate to-wound roll: a weapon's Rend hits the Save
## directly and Damage applies right after a failed save. To-hit is a flat
## roll against the weapon's to_hit_stat.
func resolve_to_hit(_attacker, weapon: WeaponProfile, _target, ctx: Dictionary, dice: DiceRoller) -> RollResult:
	var chain := ModifierChain.new()
	chain.flat_modifier = int(ctx.get("to_hit_modifier", 0))
	var count: int = int(ctx.get("attack_count", 1))
	return chain.apply(dice, weapon.to_hit_stat, count)


## Pass-through — see class doc. Keeps the AttackResolver pipeline the same
## shape across both rulesets.
func resolve_to_wound(_weapon, _target, hits: RollResult, _ctx: Dictionary, _dice: DiceRoller) -> RollResult:
	return hits


## Armor save modified by Rend (-ap_or_rend), plus a second, unmodified Ward
## save pass over whatever the armor save didn't stop, if the unit has one.
## The returned RollResult's `successes` is the combined total saved
## (armor + ward) — allocate_wounds treats `wounds.successes - save.successes`
## as the number of failed saves needing damage.
func resolve_save(target, weapon: WeaponProfile, wounds: RollResult, _ctx: Dictionary, dice: DiceRoller) -> RollResult:
	var stats: AoSUnitStats = target.stats
	var armor_chain := ModifierChain.new()
	armor_chain.flat_modifier = -weapon.ap_or_rend
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


## D6 + models_lost_this_turn vs Bravery; fails if the total exceeds Bravery.
## No test is needed (auto-pass) if the unit lost no models this turn.
func resolve_battleshock(unit: UnitInstance, models_lost_this_turn: int, dice: DiceRoller) -> bool:
	if models_lost_this_turn <= 0:
		return true
	var stats: AoSUnitStats = unit.stats
	var total: int = dice.roll_single(6) + models_lost_this_turn
	return total <= stats.bravery


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
