extends SceneTree

# Mocks
class MockUnit:
	extends Node2D
	var survivor_resource = null
	var ai_deck = []
	var grid_pos = Vector2i(0, 0)

	func get_grid_pos():
		return grid_pos

	func set_grid_pos(pos):
		grid_pos = pos

func _init():
	_run_tests()

func _run_tests():
	print("Starting TrialManager Tests...")

	# Setup Hierarchy
	var root = Node.new()

	# Setup GridManager
	var grid_manager_script = load("res://scripts/GridManager.gd")
	var grid_manager = grid_manager_script.new()
	grid_manager.name = "GridManager"
	root.add_child(grid_manager)

	# Setup TrialManager
	var trial_manager_script = load("res://scripts/TrialManager.gd")
	var trial_manager = trial_manager_script.new()
	trial_manager.name = "TrialManager"
	root.add_child(trial_manager)

	# Mock GameManager (global)
	# Since GameManager is an autoload, we might have issues if it's not present.
	# But TrialManager uses GameManager.current_roster.
	# We can inject a mock or assume the real one is loaded if we ran a scene.
	# Here we are running a script. We need to handle GameManager.
	# Since we can't easily mock Singletons in this script runner unless we define it,
	# we'll skip the GameManager part in _reset_survivor_turn_states for now
	# (TrialManager checks if GameManager is available, but relies on GridManager units mostly).

	# Setup Units
	var survivor = MockUnit.new()
	survivor.name = "Survivor"
	survivor.grid_pos = Vector2i(5, 5)
	survivor.survivor_resource = load("res://resources/SurvivorResource.gd").new()
	grid_manager.add_child(survivor)

	var boss = MockUnit.new()
	boss.name = "Boss"
	boss.grid_pos = Vector2i(10, 10)
	var ai_card = load("res://scripts/ai_card_resource.gd").new()
	ai_card.targeting_priority = "Closest"
	boss.ai_deck = [ai_card]
	grid_manager.add_child(boss)

	# Init
	grid_manager._ready()
	trial_manager._ready()

	# Test 1: Initialization
	assert(trial_manager.current_phase == trial_manager.Phase.PLAYER_PHASE, "Should start in Player Phase")
	assert(trial_manager.turn_states.has(survivor), "Survivor should have turn state")
	assert(trial_manager.turn_states[survivor].can_move == true, "Survivor should be able to move")
	print("Test 1: Initialization Passed")

	# Test 2: Player Movement
	var target_pos = Vector2i(5, 6)
	trial_manager._on_unit_move_requested(survivor, target_pos)

	assert(survivor.grid_pos == target_pos, "Survivor should have moved")
	assert(trial_manager.turn_states[survivor].can_move == false, "Survivor should have consumed move")
	print("Test 2: Player Movement Passed")

	# Test 2.5: Player Attack & End Turn
	# Reset states for testing attack (normally reset at phase start)
	trial_manager.turn_states[survivor].can_act = true

	# Spawn a dummy enemy adjacent to survivor
	var enemy = MockUnit.new()
	enemy.grid_pos = Vector2i(5, 7) # Survivor moved to 5,6
	grid_manager.add_child(enemy)
	grid_manager._refresh_occupancy_map()

	trial_manager._on_interaction_requested(survivor, enemy)
	assert(trial_manager.turn_states[survivor].can_act == false, "Survivor should have consumed act")
	# We can't easily assert signal emission in this script without connecting it,
	# but the state change confirms execution.

	# End Turn
	trial_manager.end_turn()
	assert(trial_manager.current_phase == trial_manager.Phase.MONSTER_PHASE, "Should switch to Monster Phase")
	print("Test 2.5: Player Attack & End Turn Passed")

	# Test 3: Monster Phase Logic (Targeting & Movement)
	# Reset Boss
	boss.grid_pos = Vector2i(10, 10)
	survivor.grid_pos = Vector2i(10, 13) # Dist 3
	grid_manager._refresh_occupancy_map() # Important

	# Run Monster Turn
	trial_manager._run_monster_turn()

	# Boss should move towards Survivor (Closest)
	# Boss at (10, 10), Target at (10, 13).
	# Path: (10, 11) -> (10, 12).
	# Since it only takes one step per turn in this logic (or did I implement full path? I implemented one step).
	# Code: `var next_step = _get_next_step(...)` ... `move_unit(...)`. One step.

	assert(boss.grid_pos == Vector2i(10, 11), "Boss should have moved towards survivor (10, 11), but is at " + str(boss.grid_pos))
	print("Test 3: Monster Logic Passed")

	# Test 4: Targeting Priority
	var injured_survivor = MockUnit.new()
	injured_survivor.grid_pos = Vector2i(0, 0)
	injured_survivor.survivor_resource = load("res://resources/SurvivorResource.gd").new()
	injured_survivor.survivor_resource.body_parts["Head"].is_injured = true
	grid_manager.add_child(injured_survivor)
	grid_manager._refresh_occupancy_map()

	boss.ai_deck[0].targeting_priority = "Most Injured"
	boss.grid_pos = Vector2i(5, 5) # Closer to original survivor (10, 13) or (5, 6), but injured is at (0,0)

	# Actually injured is at (0,0), distance 10.
	# Survivor is at (10, 13), distance ~13.
	# Wait, let's make injured FAR away and healthy CLOSE.
	injured_survivor.grid_pos = Vector2i(0, 0) # Dist 10 from (5,5)
	survivor.grid_pos = Vector2i(6, 6) # Dist 2 from (5,5)
	grid_manager._refresh_occupancy_map()

	# Run turn
	trial_manager._run_monster_turn()

	# Should target injured survivor at (0,0), so move towards (0,0) -> (4, 5) or (5, 4).
	# If it targeted survivor at (6,6), it would move to (6, 5) or (5, 6).

	var possible_steps_towards_injured = [Vector2i(4, 5), Vector2i(5, 4)]
	assert(boss.grid_pos in possible_steps_towards_injured, "Boss should target injured survivor. Pos: " + str(boss.grid_pos))
	print("Test 4: Targeting Priority Passed")

	print("All Tests Passed!")
	quit()
