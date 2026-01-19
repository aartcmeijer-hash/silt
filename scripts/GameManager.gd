extends Node

signal phase_changed(new_phase)
signal society_updated
signal innovation_unlocked(innovation_name)
signal survivor_died(survivor_name, cause)
signal chronicle_log(message)

var active_society: SocietyResource
var current_roster: Array[SurvivorResource] = []
var next_encounter_boss: String = ""

# Assuming these are just placeholders for now as we don't have the actual scene files.
const SCENE_PATHS = {
	"OMEN": "res://scenes/omen.tscn",
	"TRIAL": "res://scenes/trial.tscn",
	"SILT": "res://scenes/silt.tscn"
}

func _ready():
	# Check if society is initialized. If not, it's a fresh boot or needs loading.
	# For now, if no active_society, we assume New Game.
	if not active_society:
		active_society = SocietyResource.new()

func start_new_game():
	# 1. Chronicle Entry
	emit_signal("chronicle_log", "Decade 1: We pulled ourselves from the mud near the Source. The Nile provides, but the shadows move.")

	# 2. Initialize Society
	active_society.current_decade = 1
	active_society.resources = {}
	active_society.unlocked_innovations = []

	# 3. Generate 4 Survivors
	current_roster.clear()
	for i in range(4):
		var survivor = SurvivorResource.new()
		survivor.survivor_name = "Survivor " + str(i + 1)
		survivor.age_decades = 0
		survivor.traits = ["Raw Clay"]

		# Set Armor: 1 on Torso, 0 on others (default is 0)
		survivor.body_parts["Torso"]["armor"] = 1

		current_roster.append(survivor)

	# 4. Transition to Omen
	change_phase("OMEN")

func log_chronicle(message: String):
	emit_signal("chronicle_log", message)

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
