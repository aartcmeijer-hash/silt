extends SceneTree

# Mocks
class MockGridManager:
	extends Node
	signal move_requested(unit, target_pos)

	var occupancy_map = {}

	func is_valid_coord(pos):
		return true

class MockUnit:
	extends Node
	var survivor_resource = null
	var ai_deck = null
	var hit_location_deck = null

func _init():
	print("Starting Test: Resource Duplication")

	# Setup Scene Tree Structure
	var root = Node.new()
	get_root().add_child(root)

	var grid_manager = MockGridManager.new()
	grid_manager.name = "GridManager"
	root.add_child(grid_manager)

	# Setup Resources
	var shared_survivor_res = load("res://scripts/survivor_resource.gd").new()
	shared_survivor_res.survivor_name = "SharedSurvivor"
	shared_survivor_res.body_parts["Head"]["armor"] = 5

	var shared_ai_card = load("res://scripts/ai_card_resource.gd").new()
	shared_ai_card.card_name = "SharedCard"
	var shared_ai_deck = [shared_ai_card]

	# Setup Units
	var survivor_1 = MockUnit.new()
	survivor_1.name = "Survivor1"
	survivor_1.survivor_resource = shared_survivor_res

	var survivor_2 = MockUnit.new()
	survivor_2.name = "Survivor2"
	survivor_2.survivor_resource = shared_survivor_res # Intentionally sharing

	var boss = MockUnit.new()
	boss.name = "Boss"
	boss.ai_deck = shared_ai_deck

	grid_manager.occupancy_map[Vector2i(0,0)] = survivor_1
	grid_manager.occupancy_map[Vector2i(0,1)] = survivor_2
	grid_manager.occupancy_map[Vector2i(5,5)] = boss

	# Setup TrialManager
	var trial_manager = load("res://scripts/TrialManager.gd").new()
	trial_manager.name = "TrialManager"
	root.add_child(trial_manager)

	# Force _ready if not called automatically (it is when added to tree, but we want to be sure)
	# trial_manager._ready()

	# --- VERIFICATION ---

	# 1. Verify Survivors have unique resources
	if survivor_1.survivor_resource == shared_survivor_res:
		print("FAIL: Survivor 1 resource is still the original shared reference.")
	elif survivor_1.survivor_resource == survivor_2.survivor_resource:
		print("FAIL: Survivor 1 and Survivor 2 still share the same resource instance.")
	else:
		print("PASS: Survivors have unique resource instances.")

	# Verify modification independence
	survivor_1.survivor_resource.body_parts["Head"]["armor"] = 1
	if survivor_2.survivor_resource.body_parts["Head"]["armor"] != 5:
		print("FAIL: Modifying Survivor 1 affected Survivor 2.")
	else:
		print("PASS: Survivor resource modification is independent.")

	# 2. Verify Boss AI Deck is duplicated
	if boss.ai_deck == shared_ai_deck:
		print("FAIL: Boss AI Deck is still the original shared reference.")
	else:
		print("PASS: Boss AI Deck is a new instance.")

		# Check if contents are duplicated (deep copy)
		if boss.ai_deck[0] == shared_ai_card:
			# Note: duplicate(true) on Array with objects duplicates the objects.
			# If the requirement is just the array being unique, checking the array is enough.
			# But prompt said "Boss resources are duplicated".
			# Let's check if the card is a new instance.
			print("FAIL: Boss AI Card is still the original shared reference.")
		else:
			print("PASS: Boss AI Card is a new instance.")

	quit()
