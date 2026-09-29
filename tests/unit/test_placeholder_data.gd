extends GutTest
## Sanity-checks that the .tres unit/weapon data loads correctly and typed
## correctly as AoSUnitStats/FortyKUnitStats. The AoS4 units (Judicators,
## Chaos Warriors) are real Age of Sigmar 4th-edition warscroll data as best
## recalled at the time of writing — verify the exact numbers against the
## current official warscroll/Warhammer app before relying on them for a
## real game, per the project's standing "verify before real data" note.
## The 40k units (Intercessor Squad, Ork Boyz) are real 40k 11th-edition
## datasheet data as best recalled at writing time (Phase 5f port) — same
## "verify against the current official datasheet" caveat as the AoS4 units.


func test_aos_judicators_loads_with_correct_type_and_fields() -> void:
	var unit: AoSUnitStats = load("res://data/aos/units/stormcast_judicators.tres")
	assert_not_null(unit)
	assert_eq(unit.unit_id, &"aos.stormcast_eternals.judicators")
	assert_eq(unit.models_per_unit, 5)
	assert_eq(unit.bravery, 6)
	assert_eq(unit.weapons.size(), 2)
	assert_eq(unit.weapons[0].weapon_name, "Skybolt Bow")
	assert_eq(unit.weapons[1].weapon_name, "Judicator Shortsword")
	assert_gt(unit.weapons[0].range_inches, 0.0, "the Skybolt Bow should be a ranged weapon")
	assert_eq(unit.weapons[1].range_inches, 0.0, "the shortsword should be melee")


func test_aos_chaos_warriors_loads() -> void:
	var unit: AoSUnitStats = load("res://data/aos/units/slaves_to_darkness_warriors.tres")
	assert_not_null(unit)
	assert_eq(unit.unit_id, &"aos.slaves_to_darkness.chaos_warriors")
	assert_eq(unit.health_per_model, 2)
	assert_eq(unit.bravery, 7)
	assert_eq(unit.weapons[0].weapon_name, "Chaos Hand Weapon and Shield")


func test_forty_k_intercessors_loads_with_correct_type_and_fields() -> void:
	var unit: FortyKUnitStats = load("res://data/forty_k/units/space_marine_intercessors.tres")
	assert_not_null(unit)
	assert_eq(unit.unit_id, &"forty_k.adeptus_astartes.intercessor_squad")
	assert_eq(unit.toughness, 4)
	assert_eq(unit.weapons[0].weapon_name, "Bolt Rifle")
	assert_eq(unit.weapons[0].strength_or_damage, "4")
	assert_eq(unit.weapons[0].ap_or_rend, -1)
	assert_eq(unit.weapons[1].range_inches, 0.0, "the combat knife should be melee")


func test_forty_k_ork_boyz_loads() -> void:
	var unit: FortyKUnitStats = load("res://data/forty_k/units/ork_boyz.tres")
	assert_not_null(unit)
	assert_eq(unit.models_per_unit, 10)
	assert_eq(unit.weapons.size(), 3, "Slugga, Shoota, and Choppa — two ranged options plus melee")
	assert_eq(unit.weapons[0].range_inches, 12.0)
	assert_eq(unit.weapons[1].range_inches, 18.0)
	assert_eq(unit.weapons[2].range_inches, 0.0, "the Choppa should be melee")
