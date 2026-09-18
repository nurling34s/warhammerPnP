## Abstract base for a swappable ruleset (Age of Sigmar 4th ed, Warhammer 40k 11th ed, ...).
## Concrete subclasses live in core/rules/aos/ and core/rules/forty_k/.
## Nothing here touches the scene tree — this is pure rules data/logic.
class_name RulesetProvider
extends RefCounted


## Stable identifier used for data loading/dispatch (e.g. &"aos4", &"forty_k_11e").
func get_id() -> StringName:
	assert(false, "RulesetProvider.get_id() must be overridden")
	return &""


## Ordered list of GamePhase instances for one player's turn.
func build_phase_sequence(turn_manager: TurnManager) -> Array[GamePhase]:
	assert(false, "RulesetProvider.build_phase_sequence() must be overridden")
	return []


## To-hit roll. attacker/target are UnitInstance, weapon is a WeaponProfile.
## ctx carries board-derived modifiers (range, cover, buffs/debuffs in effect).
func resolve_to_hit(attacker, weapon, target, ctx: Dictionary):
	assert(false, "RulesetProvider.resolve_to_hit() must be overridden")
	return null


## To-wound roll. AoS resolves this as a pass-through (no separate to-wound step);
## 40k resolves Strength vs Toughness here.
func resolve_to_wound(weapon, target, hits, ctx: Dictionary):
	assert(false, "RulesetProvider.resolve_to_wound() must be overridden")
	return null


## Save roll (armor save modified by Rend/AP, plus a separate unmodified
## ward/invulnerable save where the unit has one).
func resolve_save(target, weapon, wounds, ctx: Dictionary):
	assert(false, "RulesetProvider.resolve_save() must be overridden")
	return null


## Ruleset-specific wound allocation order (closest-model-first, spillover rules, etc.).
func allocate_wounds(unit, damage_events: Array) -> Array:
	assert(false, "RulesetProvider.allocate_wounds() must be overridden")
	return []


## Charge distance roll (2D6" in both games; terrain/end-point rules differ per ruleset).
func roll_charge_distance(unit, dice) -> int:
	assert(false, "RulesetProvider.roll_charge_distance() must be overridden")
	return 0


## Bravery/Battleshock (AoS4) or Leadership/Battle-shock (40k 11th ed) check.
func resolve_battleshock(unit, models_lost_this_turn: int, dice):
	assert(false, "RulesetProvider.resolve_battleshock() must be overridden")
	return null


## Unit coherency check between models of the same unit.
func check_unit_coherency(unit) -> bool:
	assert(false, "RulesetProvider.check_unit_coherency() must be overridden")
	return true


## Engagement-range distance in inches for this ruleset (AoS4: 3" from the
## unit's models; 40k 11th ed: 1" — exact thresholds to verify against each
## edition's current core rulebook before real army data is entered).
func get_engagement_range_inches() -> float:
	assert(false, "RulesetProvider.get_engagement_range_inches() must be overridden")
	return 0.0


## True if `unit` is currently within engagement range of any enemy unit in
## `all_units`. Units are treated as single points (their position_inches)
## for Phase 2 — refine to per-model distances only once per-model positions
## exist (deferred alongside detailed wound tracking).
func is_in_engagement_range(unit, all_units: Array) -> bool:
	assert(false, "RulesetProvider.is_in_engagement_range() must be overridden")
	return false


## The UnitStats subclass this ruleset expects, for data-loader validation.
func get_unit_stats_script() -> Script:
	assert(false, "RulesetProvider.get_unit_stats_script() must be overridden")
	return null
