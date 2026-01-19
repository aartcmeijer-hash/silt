class_name CombatResolver
extends Node

signal combat_log(message: String)
signal reaction_triggered(trigger_name: String)
signal survivor_died(survivor: SurvivorResource)

# Helper for dice rolling to allow mocking/overriding
func roll_dice(sides: int) -> int:
	return randi() % sides + 1

# 1. The Hit Location Deck: Survivor attacks Boss
func resolve_survivor_attack(survivor: SurvivorResource, hit_location_deck: Array[HitLocationResource]) -> void:
	if hit_location_deck.is_empty():
		emit_signal("combat_log", "Hit Location Deck is empty!")
		return

	# Draw a random HitLocationResource
	var card_index = roll_dice(hit_location_deck.size()) - 1
	var card = hit_location_deck[card_index]

	emit_signal("combat_log", "%s attacks Boss! Drawn: %s" % [survivor.survivor_name, card.location_name])

	# Reaction Trigger
	if card.reaction_trigger != "":
		emit_signal("combat_log", "Reaction Triggered: %s" % card.reaction_trigger)
		emit_signal("reaction_triggered", card.reaction_trigger)

	# Apply Damage (mocked)
	emit_signal("combat_log", "Damage applied to Boss at %s." % card.location_name)


# 2. Survivor Injury Logic: Boss hits Survivor
func resolve_boss_attack(survivor: SurvivorResource) -> void:
	# Randomize Location: Roll a D4
	var d4_roll = roll_dice(4)
	var location = ""

	match d4_roll:
		1: location = "Head"
		2: location = "Torso"
		3: location = "Arms"
		4: location = "Legs"

	emit_signal("combat_log", "Boss hits %s in the %s!" % [survivor.survivor_name, location])

	var body_part = survivor.body_parts[location]

	# Armor Check
	if body_part["armor"] > 0:
		body_part["armor"] -= 1
		emit_signal("combat_log", "Armor absorbed hit. %s Armor reduced to %d." % [location, body_part["armor"]])
	else:
		# If armor is already 0
		if not body_part["is_injured"]:
			body_part["is_injured"] = true
			emit_signal("combat_log", "%s is now Injured at the %s!" % [survivor.survivor_name, location])
		else:
			# Severe Injury: If is_injured is already true
			emit_signal("combat_log", "Severe Injury triggered for %s at %s!" % [survivor.survivor_name, location])
			roll_severe_injury(survivor, location)


# 3. The Injury Table
func roll_severe_injury(survivor: SurvivorResource, location: String) -> void:
	var d10_roll = roll_dice(10)
	emit_signal("combat_log", "Severe Injury Roll (D10): %d" % d10_roll)

	if d10_roll <= 2:
		# 1-2 (Death)
		emit_signal("combat_log", "%s has died from a severe %s injury!" % [survivor.survivor_name, location])
		emit_signal("survivor_died", survivor)

	elif d10_roll <= 9:
		# 3-9 (Maimed)
		var trait_name = "Maimed: " + location
		# Optional: Flavor traits
		match location:
			"Legs": trait_name = "Limp"
			"Arms": trait_name = "Broken Arm"
			"Head": trait_name = "Concussion"
			"Torso": trait_name = "Broken Ribs"

		survivor.traits.append(trait_name)
		survivor.body_parts[location]["is_shattered"] = true

		emit_signal("combat_log", "%s is Maimed! Gained trait: '%s'. %s is Shattered." % [survivor.survivor_name, trait_name, location])

	else:
		# 10 (Survival)
		emit_signal("combat_log", "%s survived the severe injury with no permanent damage!" % survivor.survivor_name)
