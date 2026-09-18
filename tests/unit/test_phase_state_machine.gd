extends GutTest


func test_aos_ruleset_phase_sequence_names() -> void:
	var ruleset := AoSRuleset.new()
	var tm := TurnManager.new(ruleset)
	var phases := ruleset.build_phase_sequence(tm)
	var names: Array[StringName] = []
	for phase in phases:
		names.append(phase.get_phase_name())
	assert_eq(names, [
		&"Hero Phase", &"Movement Phase", &"Shooting Phase",
		&"Charge Phase", &"Combat Phase", &"End Phase",
	])


func test_forty_k_ruleset_phase_sequence_names() -> void:
	var ruleset := FortyKRuleset.new()
	var tm := TurnManager.new(ruleset)
	var phases := ruleset.build_phase_sequence(tm)
	var names: Array[StringName] = []
	for phase in phases:
		names.append(phase.get_phase_name())
	assert_eq(names, [
		&"Command Phase", &"Movement Phase", &"Shooting Phase",
		&"Charge Phase", &"Fight Phase", &"Battle-shock Phase",
	])


func test_phase_state_machine_cycles_through_all_phases_in_order() -> void:
	var ruleset := AoSRuleset.new()
	var tm := TurnManager.new(ruleset)
	var visited: Array[StringName] = []

	tm.phase_machine.phase_changed.connect(func(phase: GamePhase): visited.append(phase.get_phase_name()))
	tm.start_match()

	# Click through every phase of the first player's turn.
	for _i in 6:
		tm.phase_machine.current_phase.request_end_phase()

	assert_eq(visited, [
		&"Hero Phase", &"Movement Phase", &"Shooting Phase",
		&"Charge Phase", &"Combat Phase", &"End Phase",
		&"Hero Phase",  # first phase of player 2's turn
	])


func test_turn_manager_alternates_players_and_advances_battle_round() -> void:
	var ruleset := AoSRuleset.new()
	var tm := TurnManager.new(ruleset)
	tm.start_match()

	assert_eq(tm.active_player, 0)
	assert_eq(tm.battle_round, 1)

	for _i in 6:
		tm.phase_machine.current_phase.request_end_phase()
	assert_eq(tm.active_player, 1, "should now be player 2's turn")
	assert_eq(tm.battle_round, 1, "round should not advance until it wraps back to player 1")

	for _i in 6:
		tm.phase_machine.current_phase.request_end_phase()
	assert_eq(tm.active_player, 0, "should be back to player 1")
	assert_eq(tm.battle_round, 2, "a full round elapsed, battle round increments")
