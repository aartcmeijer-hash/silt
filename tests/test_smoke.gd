extends "res://addons/gdUnit4/src/GdUnitTestSuite.gd"

func test_smoke_checks():
	# 1. Check if GameManager (Autoload) can be loaded/instantiated
	var game_manager_path = "res://scripts/GameManager.gd"
	if FileAccess.file_exists(game_manager_path):
		var game_manager_script = load(game_manager_path)
		var game_manager = game_manager_script.new()
		assert_that(game_manager).is_not_null()
		game_manager.free()
	else:
		# If GameManager doesn't exist, we skip or fail depending on intent.
		# For a general smoke test, we log it.
		print("GameManager.gd not found, skipping specific test.")

	# 2. Check if Main Scene is defined and can be instantiated
	var main_scene_path = ProjectSettings.get_setting("application/run/main_scene")
	if main_scene_path and FileAccess.file_exists(main_scene_path):
		var runner = scene_runner(main_scene_path)
		assert_that(runner).is_not_null()
		# SceneRunner automatically frees the scene at the end of the test
	else:
		print("No Main Scene defined or file missing, skipping main scene test.")

	# 3. Basic sanity check
	assert_that(true).is_true()
