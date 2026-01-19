extends Node

func _ready():
	# Entry point for the game.
	# Check GameManager state to decide flow.

	if GameManager:
		if GameManager.active_society and GameManager.active_society.current_decade == 0:
			print("Starting New Game...")
			GameManager.start_new_game()
		else:
			print("Existing Society Detected (Decade %d). Loading..." % GameManager.active_society.current_decade)
			# Logic to load existing game would go here.
			# For now, we defaults to Silt phase if it was implemented, or just log.
			# If we wanted to be robust, we could check the last saved phase.
	else:
		push_error("GameManager singleton not found!")
