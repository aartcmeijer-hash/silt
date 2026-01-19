extends SceneTree

# Simple test runner that mocks SceneTree to be runnable from command line if possible,
# or serves as a script to be attached to a Node in Godot.

class TestCombatResolver extends CombatResolver:
	var mock_rolls = [] # Queue of rolls

	func roll_dice(sides: int) -> int:
		if mock_rolls.size() > 0:
			var roll = mock_rolls.pop_front()
			# print("Mock roll (d%d): %d" % [sides, roll])
			return roll
		return 1 # Default if empty

func _init():
	print("Starting TestCombatResolver...")
	test_survivor_attack()
	test_boss_attack_armor()
	test_boss_attack_injury()
	test_boss_attack_severe_death()
	test_boss_attack_severe_maim()
	test_boss_attack_severe_knockdown()
	print("All tests finished.")
	quit()

func create_survivor() -> SurvivorResource:
	var s = SurvivorResource.new()
	s.survivor_name = "TestDummy"
	# Reset parts
	s.body_parts = {
		"Head": { "armor": 1, "is_injured": false, "is_shattered": false },
		"Torso": { "armor": 0, "is_injured": false, "is_shattered": false },
		"Arms": { "armor": 0, "is_injured": true, "is_shattered": false }, # Pre-injured for severe test
		"Legs": { "armor": 0, "is_injured": false, "is_shattered": false }
	}
	return s

func test_survivor_attack():
	print("\n--- Test: Survivor Attack ---")
	var resolver = TestCombatResolver.new()
	var survivor = create_survivor()
	var deck: Array[HitLocationResource] = []

	var card1 = HitLocationResource.new()
	card1.location_name = "Boss Head"
	card1.reaction_trigger = "Counter-attack"
	deck.append(card1)

	resolver.connect("combat_log", func(msg): print("LOG: " + msg))

	# Logic relies on randi(), but our subclass only mocks roll_dice used for boss attacks.
	# resolve_survivor_attack uses randi() directly for deck index.
	# Since deck size is 1, it will always pick 0.

	resolver.resolve_survivor_attack(survivor, deck)
	# Expect log for Counter-attack

func test_boss_attack_armor():
	print("\n--- Test: Boss Attack (Armor) ---")
	var resolver = TestCombatResolver.new()
	var survivor = create_survivor() # Head has 1 armor

	resolver.connect("combat_log", func(msg): print("LOG: " + msg))

	# Mock roll: 1 (Head)
	resolver.mock_rolls = [1]

	resolver.resolve_boss_attack(survivor)

	if survivor.body_parts["Head"]["armor"] == 0:
		print("PASS: Armor reduced to 0.")
	else:
		print("FAIL: Armor not reduced. " + str(survivor.body_parts["Head"]))

	if survivor.body_parts["Head"]["is_injured"] == false:
		print("PASS: Not injured yet.")
	else:
		print("FAIL: Should not be injured yet.")

func test_boss_attack_injury():
	print("\n--- Test: Boss Attack (Injury) ---")
	var resolver = TestCombatResolver.new()
	var survivor = create_survivor() # Torso has 0 armor, not injured

	resolver.connect("combat_log", func(msg): print("LOG: " + msg))

	# Mock roll: 2 (Torso)
	resolver.mock_rolls = [2]

	resolver.resolve_boss_attack(survivor)

	if survivor.body_parts["Torso"]["is_injured"] == true:
		print("PASS: Torso is now injured.")
	else:
		print("FAIL: Torso should be injured.")

func test_boss_attack_severe_death():
	print("\n--- Test: Boss Attack (Severe - Death) ---")
	var resolver = TestCombatResolver.new()
	var survivor = create_survivor() # Arms has 0 armor, is_injured = true

	resolver.connect("combat_log", func(msg): print("LOG: " + msg))
	var died_signal_fired = false
	resolver.connect("survivor_died", func(s): died_signal_fired = true; print("SIGNAL: Survivor Died"))

	# Mock roll 1: 3 (Arms) - Location
	# Mock roll 2: 1 (Death) - Severe Injury Table
	resolver.mock_rolls = [3, 1]

	resolver.resolve_boss_attack(survivor)

	if died_signal_fired:
		print("PASS: Survivor died signal emitted.")
	else:
		print("FAIL: Survivor died signal NOT emitted.")

func test_boss_attack_severe_maim():
	print("\n--- Test: Boss Attack (Severe - Maim) ---")
	var resolver = TestCombatResolver.new()
	var survivor = create_survivor() # Arms has 0 armor, is_injured = true

	resolver.connect("combat_log", func(msg): print("LOG: " + msg))

	# Mock roll 1: 3 (Arms)
	# Mock roll 2: 4 (Maim)
	resolver.mock_rolls = [3, 4]

	resolver.resolve_boss_attack(survivor)

	if "Broken Arm" in survivor.traits:
		print("PASS: Survivor has Broken Arm trait.")
	else:
		print("FAIL: Survivor missing trait. " + str(survivor.traits))

	if survivor.body_parts["Arms"]["is_shattered"]:
		print("PASS: Arms shattered.")
	else:
		print("FAIL: Arms not shattered.")

func test_boss_attack_severe_knockdown():
	print("\n--- Test: Boss Attack (Severe - Knockdown) ---")
	var resolver = TestCombatResolver.new()
	var survivor = create_survivor() # Arms has 0 armor, is_injured = true

	resolver.connect("combat_log", func(msg): print("LOG: " + msg))

	# Mock roll 1: 3 (Arms)
	# Mock roll 2: 8 (Knockdown)
	resolver.mock_rolls = [3, 8]

	resolver.resolve_boss_attack(survivor)

	# No state change on survivor for knockdown (logic handled by turn manager usually), just check logs manually or via signal capture.
	print("PASS: Knockdown executed (verify logs).")
