extends SceneTree

func _init():
	print("Starting UI Verification Test...")

	# Load Scripts and Scenes
	var GameManagerScript = load("res://scripts/GameManager.gd")
	var SurvivorCardScene = load("res://scenes/SurvivorCard.tscn")
	var MainUIScene = load("res://scenes/MainUI.tscn")
	var SurvivorResource = load("res://scripts/survivor_resource.gd")

	# Setup Mock GameManager (since it's an autoload in real game, we need to mimic it or rely on it being present if autoloaded)
	# But in a script run with -s, autoloads might not be present unless configured.
	# I will check if GameManager is available, if not, I'll instantiate it and add to root.

	var game_manager
	if get_root().has_node("GameManager"):
		game_manager = get_root().get_node("GameManager")
	else:
		game_manager = GameManagerScript.new()
		game_manager.name = "GameManager"
		get_root().add_child(game_manager)
		# Force _ready
		# game_manager._ready() # _ready is called on add_child usually

	# Create Main UI
	var main_ui = MainUIScene.instantiate()
	get_root().add_child(main_ui)

	# Verify Layout Responsiveness (Logic Check)
	print("Verifying Layout Logic...")
	main_ui._apply_layout() # Triggers logic based on current viewport (likely 0x0 or default in headless)
	# Mock viewport size logic?
	# I can't easily resize the window in headless script.
	# But I can call the logic function directly or inspect the script logic which I already wrote.
	# Let's verify structure.
	if main_ui.main_container.vertical == (get_root().get_viewport().get_visible_rect().size.aspect() <= 1.0):
		print("SUCCESS: Layout orientation matches aspect ratio logic.")
	else:
		print("FAILURE: Layout orientation mismatch.")

	# Verify Survivor Card Colors
	print("Verifying Survivor Card...")
	var survivor = SurvivorResource.new()
	survivor.survivor_name = "Test Survivor"
	survivor.body_parts["Head"]["armor"] = 1 # White
	survivor.body_parts["Torso"]["is_injured"] = true # Yellow
	survivor.body_parts["Arms"]["is_shattered"] = true # Red
	# Legs default (0 armor, healthy) -> Gray/White based on my logic (Light Gray)

	var card = SurvivorCardScene.instantiate()
	main_ui.hud_container.get_node("SurvivorListScroll/SurvivorList").add_child(card)
	card.set_survivor(survivor)

	# Check Colors
	# Head (Armor > 0) -> White
	var head_style = card.head_panel.get_theme_stylebox("panel")
	if head_style.bg_color == Color.WHITE:
		print("SUCCESS: Head Color is White (Armor)")
	else:
		print("FAILURE: Head Color is " + str(head_style.bg_color))

	# Torso (Injured) -> Yellow
	var torso_style = card.torso_panel.get_theme_stylebox("panel")
	if torso_style.bg_color == Color.YELLOW:
		print("SUCCESS: Torso Color is Yellow (Injured)")
	else:
		print("FAILURE: Torso Color is " + str(torso_style.bg_color))

	# Arms (Shattered) -> Red
	var arms_style = card.arms_panel.get_theme_stylebox("panel")
	if arms_style.bg_color == Color.RED:
		print("SUCCESS: Arms Color is Red (Shattered)")
	else:
		print("FAILURE: Arms Color is " + str(arms_style.bg_color))

	# Test Death (Head Shattered)
	print("Verifying Death Logic...")
	survivor.body_parts["Head"]["is_shattered"] = true
	card.update_ui()
	head_style = card.head_panel.get_theme_stylebox("panel")
	if head_style.bg_color == Color.BLACK:
		print("SUCCESS: Head Color is Black (Dead)")
	else:
		print("FAILURE: Head Color is " + str(head_style.bg_color) + " (Expected Black)")

	# Verify Chronicle Signals
	print("Verifying Chronicle...")
	var chronicle = main_ui.hud_container.get_node("Chronicle")
	# Emit signal
	game_manager.emit_signal("innovation_unlocked", "Fire")
	await get_tree().process_frame

	# Check for child label
	var log_labels = chronicle.log_container.get_children()
	if log_labels.size() > 0:
		if "Fire" in log_labels[-1].text:
			print("SUCCESS: Chronicle received innovation unlocked.")
		else:
			print("FAILURE: Chronicle text mismatch: " + log_labels[-1].text)
	else:
		print("FAILURE: Chronicle has no entries.")

	print("All tests completed.")
	quit()
