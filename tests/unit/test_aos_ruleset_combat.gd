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


func _make_weapon(to_hit: int = 3, damage: String = "1", rend: int = 0, wound: int = 4) -> WeaponProfile:
	var weapon := WeaponProfile.new()
	weapon.to_hit_stat = to_hit
	weapon.wound_stat = wound
	weapon.strength_or_damage = damage
	weapon.ap_or_rend = rend
	return weapon


func _make_unit(save: int = 4, ward: int = 0, health_per_model: int = 2) -> UnitInstance:
	var stats := AoSUnitStats.new()
	stats.save = save
	stats.ward_save = ward
	stats.models_per_unit = 3
	stats.health_per_model = health_per_model
	return UnitInstance.new(stats, 1)


func test_resolve_to_hit_uses_weapon_to_hit_stat_and_attack_count() -> void:
	var ruleset := AoSRuleset.new()
	var dice := ScriptedDice.new([3, 4, 2])  # target 3+: hit, hit, fail
	var weapon := _make_weapon(3)
	var result := ruleset.resolve_to_hit(null, weapon, null, {"attack_count": 3}, dice)
	assert_eq(result.successes, 2)


func test_resolve_to_wound_rolls_against_weapon_wound_stat() -> void:
	var ruleset := AoSRuleset.new()
	var weapon := _make_weapon(3, "1", 0, 4)  # wound 4+
	var hits := RollResult.new()
	hits.successes = 3
	var dice := ScriptedDice.new([4, 5, 2])  # target 4+: wound, wound, fail
	var result := ruleset.resolve_to_wound(weapon, null, hits, {}, dice)
	assert_eq(result.successes, 2)


func test_resolve_save_reduced_by_rend() -> void:
	var ruleset := AoSRuleset.new()
	var target := _make_unit(4, 0)  # save 4+, rend -1 -> effective 5+
	var weapon := _make_weapon(3, "1", -1)  # Rend is stored signed, like 40k's AP (see chaos_glaive.tres)
	var wounds := RollResult.new()
	wounds.successes = 2
	var dice := ScriptedDice.new([5, 4])  # 5 saves (>=5), 4 fails (<5)
	var save := ruleset.resolve_save(target, weapon, wounds, {}, dice)
	assert_eq(save.successes, 1, "only the roll of 5 should meet the rend-modified 5+ save")


func test_resolve_save_ward_catches_failed_armor_saves() -> void:
	var ruleset := AoSRuleset.new()
	var target := _make_unit(4, 5)  # save 4+, ward 5+
	var weapon := _make_weapon(3, "1", 0)
	var wounds := RollResult.new()
	wounds.successes = 2
	var dice := ScriptedDice.new([1, 2, 5, 1])  # armor: both fail (1,2 < 4); ward on those 2 failures: 5 saves, 1 fails
	var save := ruleset.resolve_save(target, weapon, wounds, {}, dice)
	assert_eq(save.successes, 1, "one ward save should catch one of the two failed armor saves")


func test_allocate_wounds_rolls_damage_and_applies_to_model() -> void:
	var ruleset := AoSRuleset.new()
	var target := _make_unit(4, 0, 2)
	var weapon := _make_weapon(3, "D3", 0)
	var dice := ScriptedDice.new([2])  # D3 damage rolls a 2
	var events: Array = [DamageEvent.new(weapon)]

	var results := ruleset.allocate_wounds(target, events, dice)

	assert_eq(results[0].damage_applied, 2)
	assert_eq(target.models_alive, 2, "the first model should have died from 2 damage against 2 wounds")
	assert_eq(target.models_lost_this_turn, 1)
