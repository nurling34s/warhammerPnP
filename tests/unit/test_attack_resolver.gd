extends GutTest

## Same scripted-dice pattern as test_dice_roller.gd.
class ScriptedDice:
	extends DiceRoller

	var _queue: Array[int] = []

	func _init(sequence: Array[int]) -> void:
		_queue = sequence.duplicate()

	func roll(n: int, sides: int = 6) -> Array[int]:
		var out: Array[int] = []
		for _i in n:
			out.append(roll_single(sides))
		return out

	func roll_single(_sides: int = 6) -> int:
		return _queue.pop_front()


func test_aos_full_pipeline_end_to_end() -> void:
	# 2 attacks, to_hit 3+, no rend, target save 4+, damage 1 per failed save.
	var attacker_stats := AoSUnitStats.new()
	var attacker := UnitInstance.new(attacker_stats, 0)

	var target_stats := AoSUnitStats.new()
	target_stats.save = 4
	target_stats.models_per_unit = 2
	target_stats.health_per_model = 1
	var target := UnitInstance.new(target_stats, 1)

	var weapon := WeaponProfile.new()
	weapon.attacks = "2"
	weapon.to_hit_stat = 3
	weapon.strength_or_damage = "1"

	# attack_count roll not needed (flat "2"); to-hit: 3,4 both hit;
	# to-wound (AoS4 has a real wound roll, default wound_stat 4+): 4,5 both wound;
	# save: 1,2 both fail.
	var dice := ScriptedDice.new([3, 4, 4, 5, 1, 2])
	var ruleset := AoSRuleset.new()
	var resolver := AttackResolver.new(ruleset, dice)

	var outcome := resolver.resolve_attack(attacker, weapon, target, {})

	assert_eq(outcome.to_hit.successes, 2)
	assert_eq(outcome.save.successes, 0)
	assert_eq(outcome.models_slain, 2)
	assert_true(target.is_destroyed)


func test_forty_k_full_pipeline_end_to_end() -> void:
	var attacker_stats := FortyKUnitStats.new()
	var attacker := UnitInstance.new(attacker_stats, 0)

	var target_stats := FortyKUnitStats.new()
	target_stats.toughness = 4
	target_stats.save = 4
	target_stats.models_per_unit = 1
	target_stats.health_per_model = 2
	var target := UnitInstance.new(target_stats, 1)

	var weapon := WeaponProfile.new()
	weapon.attacks = "1"
	weapon.to_hit_stat = 3
	weapon.strength_or_damage = "4"  # == toughness -> 4+ to wound
	weapon.ap_or_rend = 0
	weapon.damage = "2"

	# to-hit: 3 (hit); to-wound: 4 (wound); save: 1 (fail) -> damage 2 kills the 2-wound model.
	var dice := ScriptedDice.new([3, 4, 1])
	var ruleset := FortyKRuleset.new()
	var resolver := AttackResolver.new(ruleset, dice)

	var outcome := resolver.resolve_attack(attacker, weapon, target, {})

	assert_eq(outcome.to_hit.successes, 1)
	assert_eq(outcome.to_wound.successes, 1)
	assert_eq(outcome.save.successes, 0)
	assert_eq(outcome.models_slain, 1)
	assert_true(target.is_destroyed)


func test_attack_resolver_logs_to_combat_log_when_given_one() -> void:
	var attacker_stats := AoSUnitStats.new()
	attacker_stats.display_name = "Attacker"
	var attacker := UnitInstance.new(attacker_stats, 0)

	var target_stats := AoSUnitStats.new()
	target_stats.display_name = "Target"
	target_stats.save = 6
	var target := UnitInstance.new(target_stats, 1)

	var weapon := WeaponProfile.new()
	weapon.weapon_name = "Test Weapon"
	weapon.attacks = "1"
	weapon.to_hit_stat = 2

	var dice := ScriptedDice.new([6, 4, 1])  # hit, then wound (default 4+), then failed save (1 always fails)
	var log := CombatLog.new()
	var resolver := AttackResolver.new(AoSRuleset.new(), dice, log)

	resolver.resolve_attack(attacker, weapon, target, {})

	assert_eq(log.entries.size(), 1)
	assert_eq(log.entries[0].attacker, "Attacker")
	assert_eq(log.entries[0].target, "Target")
	assert_eq(log.entries[0].weapon, "Test Weapon")
	assert_eq(log.entries[0].kind, "attack")
	assert_eq(log.entries[0].attacks, 1)
	assert_eq(log.entries[0].hit_rolls, [6])
	assert_eq(log.entries[0].wound_rolls, [4])
	assert_eq(log.entries[0].save_rolls, [1])
	assert_eq(log.entries[0].hit_target, 2)


func test_combat_log_records_moves_and_messages() -> void:
	var stats := AoSUnitStats.new()
	stats.display_name = "Judicators"
	var unit := UnitInstance.new(stats, 0)
	var log := CombatLog.new()

	log.log_move(unit, 4.8, 5.0)
	log.log_message("Player 1 — Movement Phase")

	assert_eq(log.entries[0].kind, "move")
	assert_eq(log.entries[0].unit, "Judicators")
	assert_almost_eq(log.entries[0].distance, 4.8, 0.001)
	assert_eq(log.entries[1].kind, "message")
	assert_eq(log.entries[1].text, "Player 1 — Movement Phase")


func test_no_combat_log_does_not_error() -> void:
	var attacker := UnitInstance.new(AoSUnitStats.new(), 0)
	var target := UnitInstance.new(AoSUnitStats.new(), 1)
	var weapon := WeaponProfile.new()
	weapon.attacks = "1"
	var dice := ScriptedDice.new([1])
	var resolver := AttackResolver.new(AoSRuleset.new(), dice)
	var outcome := resolver.resolve_attack(attacker, weapon, target, {})
	assert_not_null(outcome)
