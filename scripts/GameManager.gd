extends Node

signal phase_changed(new_phase)
signal society_updated

var active_society: SocietyResource
var current_roster: Array[SurvivorResource] = []

# Assuming these are just placeholders for now as we don't have the actual scene files.
const SCENE_PATHS = {
	"OMEN": "res://scenes/omen.tscn",
	"TRIAL": "res://scenes/trial.tscn",
	"SILT": "res://scenes/silt.tscn"
}

func _ready():
	# Initialize a default society if none exists, or load it.
	# For now, we'll create a new one for testing purposes if it's null.
	if not active_society:
		active_society = SocietyResource.new()

func change_phase(target_phase: String):
	var scene_path = ""
	match target_phase:
		"OMEN":
			scene_path = SCENE_PATHS["OMEN"]
		"TRIAL":
			scene_path = SCENE_PATHS["TRIAL"]
		"SILT":
			scene_path = SCENE_PATHS["SILT"]
		_:
			push_error("Unknown phase: " + target_phase)
			return

	# In a real environment, we would check if the file exists or handle errors.
	# get_tree().change_scene_to_file(scene_path)

	# Since we are mocking the environment and don't have the scenes,
	# we will just emit the signal to simulate the transition.
	# If running in actual Godot, uncomment the line above.

	# For the purpose of this task, I will include the call but comment it out
	# or wrap it in a check if the tree exists (it should in a Node).
	if is_inside_tree():
		var error = get_tree().change_scene_to_file(scene_path)
		if error != OK:
			push_error("Failed to change scene to " + scene_path + ". Error code: " + str(error))

	emit_signal("phase_changed", target_phase)

func advance_decade():
	if active_society:
		active_society.current_decade += 1

	var survivors_to_remove = []

	for survivor in current_roster:
		survivor.age_decades += 1
		if survivor.age_decades > 5: # Elder limit > 5 decades
			survivors_to_remove.append(survivor)
			# Handle retirement/death logic here
			# print("Survivor retired/died")

	for s in survivors_to_remove:
		current_roster.erase(s)

	emit_signal("society_updated")
