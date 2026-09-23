## Ruleset-agnostic orchestrator for one weapon-vs-target attack:
## rolls the attack count, then delegates To Hit -> To Wound -> Save ->
## Allocate Wounds to the active RulesetProvider, threading RollResults
## between steps. All the ruleset-specific math lives in AoSRuleset/
## FortyKRuleset — this class only sequences it.
class_name AttackResolver
extends RefCounted

var ruleset: RulesetProvider
var dice: DiceRoller
var combat_log: CombatLog


func _init(ruleset_provider: RulesetProvider, dice_roller: DiceRoller, log: CombatLog = null) -> void:
	ruleset = ruleset_provider
	dice = dice_roller
	combat_log = log


## ctx carries board-derived modifiers (range_inches, in_cover, to_hit_modifier,
## ...). "attack_count" is added automatically from weapon.attacks and should
## not be passed in by the caller.
func resolve_attack(attacker: UnitInstance, weapon: WeaponProfile, target: UnitInstance, ctx: Dictionary = {}) -> AttackOutcome:
	var full_ctx: Dictionary = ctx.duplicate()
	full_ctx["attack_count"] = DiceNotation.roll(weapon.attacks, dice)

	var to_hit: RollResult = ruleset.resolve_to_hit(attacker, weapon, target, full_ctx, dice)
	var to_wound: RollResult = ruleset.resolve_to_wound(weapon, target, to_hit, full_ctx, dice)
	var save: RollResult = ruleset.resolve_save(target, weapon, to_wound, full_ctx, dice)

	var failed_saves: int = to_wound.successes - save.successes
	var damage_events: Array = []
	for _i in failed_saves:
		damage_events.append(DamageEvent.new(weapon))

	var models_before: int = target.models_alive
	var allocation: Array = ruleset.allocate_wounds(target, damage_events, dice)
	var models_slain: int = models_before - target.models_alive

	var outcome := AttackOutcome.new(to_hit, to_wound, save, allocation, models_slain)
	if combat_log:
		combat_log.log_attack(attacker, target, weapon, outcome)
	return outcome
