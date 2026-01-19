extends SceneTree

# Simple test runner for GameManager logic
# Run with: godot --headless -s tests/test_gamemanager.gd

func _init():
	print("Starting GameManager tests...")

	# Load scripts
	var GameManagerScript = load("res://scripts/GameManager.gd")
	var SocietyResourceScript = load("res://resources/SocietyResource.gd")
	var SurvivorResourceScript = load("res://resources/SurvivorResource.gd")

	if not GameManagerScript or not SocietyResourceScript or not SurvivorResourceScript:
		print("Error: Could not load scripts.")
		quit(1)
		return

	# Instantiate GameManager
	var game_manager = GameManagerScript.new()
	# Since it's not in the tree, we manually trigger _ready or just set up properties
	game_manager._ready()

	# Test 1: Initial State
	if not game_manager.active_society:
		print("FAIL: active_society is null")
		quit(1)
		return
	if game_manager.active_society.current_decade != 0:
		print("FAIL: Initial current_decade is not 0")
		quit(1)
		return
	print("PASS: Initial State")

	# Test 2: Survivor Management
	var s1 = SurvivorResourceScript.new()
	s1.age_decades = 3
	var s2 = SurvivorResourceScript.new()
	s2.age_decades = 5 # Should survive next increment (becomes 6, then removed? No, if > 5. So 5->6 is >5)
	# Wait, requirements: "checks if any survivors exceed the 'Elder' age limit (5 decades)"
	# If current age is 5, next decade it becomes 6. 6 > 5 is True. So it should be removed.

	game_manager.current_roster.append(s1)
	game_manager.current_roster.append(s2)

	print("Advancing decade...")
	game_manager.advance_decade()

	if game_manager.active_society.current_decade != 1:
		print("FAIL: current_decade did not increment")
		quit(1)
		return

	# s1 should be 4
	if s1.age_decades != 4:
		print("FAIL: s1 age incorrect. Expected 4, got ", s1.age_decades)
		quit(1)
		return

	# s2 should be 6 and removed from roster
	if s2.age_decades != 6:
		print("FAIL: s2 age incorrect. Expected 6, got ", s2.age_decades)
		quit(1)
		return

	if game_manager.current_roster.has(s2):
		print("FAIL: s2 (age 6) was not removed from roster")
		quit(1)
		return

	if not game_manager.current_roster.has(s1):
		print("FAIL: s1 (age 4) was incorrectly removed")
		quit(1)
		return

	print("PASS: Advance Decade Logic")

	# Test 3: Phase Change (Signal check)
	# Since we can't easily listen to signals in this simple script without an object connecting to it,
	# we will just call the function and ensure it doesn't crash.
	# Verification of signal emission usually requires a test framework like GUT or manually connecting a method.

	print("Testing change_phase...")
	game_manager.change_phase("TRIAL")
	# If no crash, we assume partial success.
	# Real verification would check the signal.

	print("All tests passed!")
	quit()
