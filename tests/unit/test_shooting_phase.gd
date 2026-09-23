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


func _make_unit(player: int, position: Vector2) -> UnitInstance:
	var stats := AoSUnitStats.new()
	var unit := UnitInstance.new(stats, player)
	unit.position_inches = position
	return unit


func _make_weapon(range_inches: float = 12.0) -> WeaponProfile:
	var weapon := WeaponProfile.new()
	weapon.range_inches = range_inches
	weapon.attacks = "1"
	weapon.to_hit_stat = 2
	weapon.strength_or_damage = "1"
	return weapon


func test_can_shoot_within_range_and_los_succeeds() -> void:
	var ruleset := AoSRuleset.new()
	var tm := TurnManager.new(ruleset)
	var phase := AoSShootingPhase.new(tm)
	var attacker := _make_unit(0, Vector2(0, 0))
	var target := _make_unit(1, Vector2(10, 0))

	var result := phase.can_shoot(attacker, _make_weapon(12.0), target, [])
	assert_true(result.ok)


func test_can_shoot_out_of_range_is_rejected() -> void:
	var ruleset := AoSRuleset.new()
	var tm := TurnManager.new(ruleset)
	var phase := AoSShootingPhase.new(tm)
	var attacker := _make_unit(0, Vector2(0, 0))
	var target := _make_unit(1, Vector2(20, 0))

	var result := phase.can_shoot(attacker, _make_weapon(12.0), target, [])
	assert_false(result.ok)
	assert_eq(result.reason, "out_of_range")


func test_can_shoot_blocked_by_terrain_is_rejected() -> void:
	var ruleset := AoSRuleset.new()
	var tm := TurnManager.new(ruleset)
	var phase := AoSShootingPhase.new(tm)
	var attacker := _make_unit(0, Vector2(0, 5))
	var target := _make_unit(1, Vector2(10, 5))

	var blocker := TerrainPiece.new()
	blocker.footprint_inches = Rect2(4, 4, 2, 2)
	blocker.blocks_line_of_sight = true

	var result := phase.can_shoot(attacker, _make_weapon(12.0), target, [blocker])
	assert_false(result.ok)
	assert_eq(result.reason, "no_line_of_sight")


func test_already_shot_unit_cannot_shoot_again() -> void:
	var ruleset := AoSRuleset.new()
	var tm := TurnManager.new(ruleset)
	var phase := AoSShootingPhase.new(tm)
	var attacker := _make_unit(0, Vector2(0, 0))
	attacker.has_shot = true
	var target := _make_unit(1, Vector2(5, 0))

	var result := phase.can_shoot(attacker, _make_weapon(12.0), target, [])
	assert_false(result.ok)
	assert_eq(result.reason, "already_shot")


func test_declare_shoot_marks_has_shot_and_resolves_attack() -> void:
	var ruleset := AoSRuleset.new()
	var tm := TurnManager.new(ruleset)
	var phase := AoSShootingPhase.new(tm)
	var attacker := _make_unit(0, Vector2(0, 0))
	var target := _make_unit(1, Vector2(5, 0))
	var dice := ScriptedDice.new([6, 1])  # hit, then failed save
	var resolver := AttackResolver.new(ruleset, dice)

	var result := phase.declare_shoot(attacker, _make_weapon(12.0), target, [], resolver)

	assert_true(result.ok)
	assert_true(attacker.has_shot)
	assert_not_null(result.outcome)


func test_get_valid_targets_excludes_friendly_and_out_of_range() -> void:
	var ruleset := AoSRuleset.new()
	var tm := TurnManager.new(ruleset)
	var phase := AoSShootingPhase.new(tm)
	var attacker := _make_unit(0, Vector2(0, 0))
	var friend := _make_unit(0, Vector2(1, 0))
	var near_enemy := _make_unit(1, Vector2(5, 0))
	var far_enemy := _make_unit(1, Vector2(50, 0))

	var targets := phase.get_valid_targets(attacker, _make_weapon(12.0), [attacker, friend, near_enemy, far_enemy], [])

	assert_eq(targets, [near_enemy])
