extends Control

func _on_consume_pressed():
	# Option A (Consume): Give all 4 survivors a temporary Strength +1 buff for the first fight.
	if GameManager:
		for survivor in GameManager.current_roster:
			survivor.temporary_buffs.append("Strength +1")

		# Set next boss
		GameManager.next_encounter_boss = "Silt-Cutter"

		GameManager.change_phase("TRIAL")

func _on_observe_pressed():
	# Option B (Observe): Add 1 Innovation Point to the active_society resources.
	if GameManager and GameManager.active_society:
		var current_points = GameManager.active_society.resources.get("Innovation", 0)
		GameManager.active_society.resources["Innovation"] = current_points + 1

		# Set next boss
		GameManager.next_encounter_boss = "Silt-Cutter"

		GameManager.change_phase("TRIAL")
