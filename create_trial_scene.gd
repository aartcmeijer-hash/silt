extends SceneTree

func _init():
	var trial_node = Node2D.new()
	trial_node.name = "Trial"

	# GridManager (Handles Camera internally)
	var grid_manager = Node2D.new()
	grid_manager.name = "GridManager"
	grid_manager.set_script(load("res://scripts/GridManager.gd"))
	trial_node.add_child(grid_manager)

	# TrialUI (CanvasLayer)
	var ui = CanvasLayer.new()
	ui.name = "CanvasLayer"
	ui.set_script(load("res://scripts/TrialUI.gd"))
	trial_node.add_child(ui)

	# TrialManager
	var trial_manager = Node.new()
	trial_manager.name = "TrialManager"
	trial_manager.set_script(load("res://scripts/TrialManager.gd"))
	trial_node.add_child(trial_manager)

	# Pack and Save
	var scene = PackedScene.new()
	var result = scene.pack(trial_node)
	if result == OK:
		var save_result = ResourceSaver.save(scene, "res://scenes/Trial.tscn")
		if save_result == OK:
			print("Trial.tscn saved successfully.")
		else:
			print("Failed to save Trial.tscn: ", save_result)
	else:
		print("Failed to pack scene: ", result)

	quit()
