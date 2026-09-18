extends GutTest
## Sanity-checks that the placeholder .tres unit/weapon data loads correctly
## and typed correctly as AoSUnitStats/FortyKUnitStats.


func test_aos_order_warriors_loads_with_correct_type_and_fields() -> void:
	var unit: AoSUnitStats = load("res://data/aos/units/test_order_warriors.tres")
	assert_not_null(unit)
	assert_eq(unit.unit_id, &"aos.test.order_warriors")
	assert_eq(unit.models_per_unit, 5)
	assert_eq(unit.bravery, 6)
	assert_eq(unit.weapons.size(), 1)
	assert_eq(unit.weapons[0].weapon_name, "Test Blade")


func test_aos_chaos_brutes_loads() -> void:
	var unit: AoSUnitStats = load("res://data/aos/units/test_chaos_brutes.tres")
	assert_not_null(unit)
	assert_eq(unit.health_per_model, 3)
	assert_eq(unit.weapons[0].ap_or_rend, 1)


func test_forty_k_imperium_squad_loads_with_correct_type_and_fields() -> void:
	var unit: FortyKUnitStats = load("res://data/forty_k/units/test_imperium_squad.tres")
	assert_not_null(unit)
	assert_eq(unit.unit_id, &"forty_k.test.imperium_squad")
	assert_eq(unit.toughness, 4)
	assert_eq(unit.weapons[0].strength_or_damage, "4")
	assert_eq(unit.weapons[0].ap_or_rend, -1)


func test_forty_k_ork_squad_loads() -> void:
	var unit: FortyKUnitStats = load("res://data/forty_k/units/test_ork_squad.tres")
	assert_not_null(unit)
	assert_eq(unit.models_per_unit, 10)
	assert_eq(unit.weapons[0].range_inches, 12.0)
