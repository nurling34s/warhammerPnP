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


func _make_weapon(to_hit: int = 3, strength: String = "4", ap: int = 0, damage: String = "1") -> WeaponProfile:
	var weapon := WeaponProfile.new()
	weapon.to_hit_stat = to_hit
	weapon.strength_or_damage = strength
	weapon.ap_or_rend = ap
	weapon.damage = damage
	return weapon


func _make_unit(toughness: int = 4, save: int = 3, invuln: int = 0, health_per_model: int = 2) -> UnitInstance:
	var stats := FortyKUnitStats.new()
	stats.toughness = toughness
	stats.save = save
	stats.invulnerable_save = invuln
	stats.models_per_unit = 3
	stats.health_per_model = health_per_model
	return UnitInstance.new(stats, 1)


func test_wound_target_table() -> void:
	var ruleset := FortyKRuleset.new()
	assert_eq(ruleset._wound_target(8, 4), 2, "S >= 2T")
	assert_eq(ruleset._wound_target(5, 4), 3, "S > T")
	assert_eq(ruleset._wound_target(4, 4), 4, "S == T")
	assert_eq(ruleset._wound_target(3, 4), 5, "S < T but S*2 > T")
	assert_eq(ruleset._wound_target(2, 5), 6, "S*2 <= T")


func test_resolve_to_wound_uses_strength_vs_toughness() -> void:
	var ruleset := FortyKRuleset.new()
	var target := _make_unit(4)  # toughness 4
	var weapon := _make_weapon(3, "4")  # S == T -> 4+
	var hits := RollResult.new()
	hits.successes = 2
	var dice := ScriptedDice.new([4, 3])  # 4 wounds, 3 fails
	var result := ruleset.resolve_to_wound(weapon, target, hits, {}, dice)
	assert_eq(result.successes, 1)


func test_resolve_save_worsened_by_ap() -> void:
	var ruleset := FortyKRuleset.new()
	var target := _make_unit(4, 3, 0)  # save 3+, AP -1 -> effective 4+
	var weapon := _make_weapon(3, "4", -1)  # ap_or_rend is stored signed, matching existing weapon data
	var wounds := RollResult.new()
	wounds.successes = 2
	var dice := ScriptedDice.new([4, 3])  # 4 saves (>=4), 3 fails (<4)
	var save := ruleset.resolve_save(target, weapon, wounds, {}, dice)
	assert_eq(save.successes, 1)


func test_resolve_save_uses_better_of_armor_and_invulnerable() -> void:
	var ruleset := FortyKRuleset.new()
	var target := _make_unit(4, 3, 5)  # armor 3+ vs AP -3 -> 6+; invuln 5+ is better
	var weapon := _make_weapon(3, "4", -3)
	var wounds := RollResult.new()
	wounds.successes = 1
	var dice := ScriptedDice.new([5])  # meets invuln 5+ but not the AP-crushed armor 6+
	var save := ruleset.resolve_save(target, weapon, wounds, {}, dice)
	assert_eq(save.successes, 1, "invulnerable save must not be reduced by AP")


func test_allocate_wounds_rolls_weapon_damage_field_not_strength() -> void:
	var ruleset := FortyKRuleset.new()
	var target := _make_unit(4, 3, 0, 2)
	var weapon := _make_weapon(3, "4", 0, "2")  # Strength 4, Damage 2 — must use damage, not strength
	var dice := ScriptedDice.new([])
	var events: Array = [DamageEvent.new(weapon)]

	var results := ruleset.allocate_wounds(target, events, dice)

	assert_eq(results[0].damage_applied, 2)
	assert_eq(target.models_alive, 2)
