class_name TrialManager
extends Node

signal phase_changed(new_phase)
signal attack_initiated(attacker, defender)

enum Phase {
	PLAYER_PHASE,
	MONSTER_PHASE
}

class TurnState:
	var can_move: bool = true
	var can_act: bool = true

var current_phase: Phase = Phase.PLAYER_PHASE
var turn_states: Dictionary = {} # Maps Node -> TurnState
var grid_manager: Node = null
var combat_resolver: CombatResolver = null
var trial_ui: TrialUI = null
var boss_node: Node2D = null

# In a real scene, this would be set or found.
# We will assume GridManager is a sibling.
func _ready():
	# Initialize Combat Resolver
	combat_resolver = CombatResolver.new()
	add_child(combat_resolver)
	combat_resolver.combat_log.connect(_on_combat_log)
	combat_resolver.survivor_died.connect(_on_survivor_died)

	# Try to find GridManager
	if get_parent():
		grid_manager = get_parent().get_node_or_null("GridManager")
		# Try to find UI
		var canvas_layer = get_parent().get_node_or_null("CanvasLayer")
		if canvas_layer and canvas_layer is TrialUI:
			trial_ui = canvas_layer

	if grid_manager:
		grid_manager.move_requested.connect(_on_unit_move_requested)
		grid_manager.interaction_requested.connect(_on_interaction_requested)
	else:
		push_warning("TrialManager: GridManager not found.")

	# Spawn Units
	spawn_units()

	_initialize_resources()

	# Initialize turn states for survivors (if any exist at start)
	start_phase(Phase.PLAYER_PHASE)

func spawn_units():
	if not grid_manager:
		return

	# Spawn Survivors
	var roster = []
	if GameManager:
		roster = GameManager.current_roster

	var start_x = 0
	var start_y = 0

	for i in range(roster.size()):
		var survivor = roster[i]
		var survivor_node = Node2D.new()
		survivor_node.name = survivor.survivor_name

		# Visuals
		var color_rect = ColorRect.new()
		color_rect.size = Vector2(40, 40)
		color_rect.color = Color.CYAN
		color_rect.position = Vector2(-20, -20)
		survivor_node.add_child(color_rect)

		# Script/Data
		survivor_node.set_meta("survivor_resource", survivor)

		# Position (2x2)
		var grid_x = start_x + (i % 2)
		var grid_y = start_y + (i / 2)
		var spawn_pos = Vector2i(grid_x, grid_y)

		grid_manager.add_child(survivor_node)
		survivor_node.position = grid_manager.grid_to_local(spawn_pos) + Vector2(32, 32)

		# Attach script
		survivor_node.set_script(load("res://scripts/UnitEntity.gd"))
		survivor_node.survivor_resource = survivor

	# Spawn Boss
	_spawn_boss(GameManager.next_encounter_boss if GameManager else "Boss")

	grid_manager._refresh_occupancy_map()

func _initialize_resources():
	if not grid_manager:
		return

	for unit in grid_manager.occupancy_map.values():
		# Duplicate Survivor Resource
		if "survivor_resource" in unit and unit.survivor_resource:
			unit.survivor_resource = unit.survivor_resource.duplicate(true)

		# Duplicate Boss Resources
		if "ai_deck" in unit and unit.ai_deck is Array:
			unit.ai_deck = unit.ai_deck.duplicate(true)

		if "hit_location_deck" in unit and unit.hit_location_deck is Array:
			unit.hit_location_deck = unit.hit_location_deck.duplicate(true)

func start_phase(new_phase: Phase):
	current_phase = new_phase
	emit_signal("phase_changed", current_phase)

	if current_phase == Phase.PLAYER_PHASE:
		_reset_survivor_turn_states()
	elif current_phase == Phase.MONSTER_PHASE:
		# Run monster turn after a short delay or immediately
		# Using call_deferred to avoid stack issues or immediate execution during state change
		call_deferred("_run_monster_turn")

func _reset_survivor_turn_states():
	turn_states.clear()
	# We need to map GameManager.current_roster to nodes in GridManager.
	# We assume nodes in GridManager have a 'resource' property or similar.

	if not grid_manager:
		return

	var all_units = grid_manager.occupancy_map.values()
	# Use GameManager if available
	var roster = []
	if GameManager:
		roster = GameManager.current_roster

	for unit in all_units:
		# Check if unit corresponds to a survivor
		# We'll check if the unit has a property that matches a resource in the roster
		# Or if the unit simply IS a survivor type.
		# For this implementation, we'll check if it has 'survivor_resource'
		if "survivor_resource" in unit and unit.survivor_resource != null:
			var state = TurnState.new()
			turn_states[unit] = state

func _on_unit_move_requested(unit, target_pos):
	if current_phase != Phase.PLAYER_PHASE:
		return

	# Update UI selection
	if trial_ui and "survivor_resource" in unit:
		trial_ui.update_survivor_status(unit.survivor_resource)

	if unit in turn_states:
		var state = turn_states[unit]
		if state.can_move:
			grid_manager.move_unit(unit, target_pos)
			state.can_move = false
		else:
			_on_combat_log("Unit has already moved this turn.")

func _on_interaction_requested(source, target):
	if current_phase != Phase.PLAYER_PHASE:
		return

	# Select unit if friendly
	if "survivor_resource" in target and target.survivor_resource:
		# Just update UI logic handled by GridManager selection mostly,
		# but if we want to support switching selection:
		grid_manager._select_unit(target)
		if trial_ui:
			trial_ui.update_survivor_status(target.survivor_resource)
		return

	# Attack if enemy
	if source in turn_states:
		var state = turn_states[source]
		if state.can_act:
			var source_pos = grid_manager.local_to_grid(source.position)
			var target_pos = grid_manager.local_to_grid(target.position)

			if _manhattan_distance(source_pos, target_pos) <= 1:
				state.can_act = false

				# Survivor attacks Boss
				if "survivor_resource" in source and target == boss_node:
					# Mock Hit Location Deck
					var deck = []
					if "hit_location_deck" in target: # Boss should have this
						deck = target.hit_location_deck
					else:
						# Create mock deck
						var card = HitLocationResource.new()
						card.location_name = "Generic Spot"
						deck.append(card)

					combat_resolver.resolve_survivor_attack(source.survivor_resource, deck)

					# Damage Boss Integrity (Assuming 1 dmg)
					if "integrity" in target:
						target.integrity -= 1
						_on_combat_log("Boss Integrity: %d" % target.integrity)
						check_game_state()
			else:
				_on_combat_log("Target out of range!")
		else:
			_on_combat_log("Unit has already acted this turn.")

func end_turn():
	if current_phase == Phase.PLAYER_PHASE:
		start_phase(Phase.MONSTER_PHASE)

func _run_monster_turn():
	if not grid_manager or not boss_node:
		start_phase(Phase.PLAYER_PHASE)
		return

	# Retrieve AI Deck
	var ai_deck = []
	if "ai_deck" in boss_node:
		ai_deck = boss_node.ai_deck

	if ai_deck.is_empty():
		_on_combat_log("Boss has no AI cards!")
		start_phase(Phase.PLAYER_PHASE)
		return

	var ai_card = ai_deck[0] # Simple: pick first card
	_on_combat_log("Boss plays: %s" % ai_card.card_name)

	# Target Selection
	var target = _get_best_target(boss_node, ai_card.targeting_priority)

	if target:
		# Movement: Step-Toward
		var start_pos = grid_manager.local_to_grid(boss_node.position)
		var target_pos = grid_manager.local_to_grid(target.position)
		var dist = _manhattan_distance(start_pos, target_pos)

		# We want to be adjacent to target
		if dist > 1:
			var next_step = _get_next_step(start_pos, target_pos)
			if next_step != start_pos:
				grid_manager.move_unit(boss_node, next_step)

		# Attack Logic
		var current_pos = grid_manager.local_to_grid(boss_node.position)
		dist = _manhattan_distance(current_pos, grid_manager.local_to_grid(target.position))

		if dist == 1:
			if "survivor_resource" in target:
				combat_resolver.resolve_boss_attack(target.survivor_resource)
				check_game_state()

	# End Monster Phase
	start_phase(Phase.PLAYER_PHASE)

func _get_best_target(boss_node, priority):
	var survivors = []
	for unit in grid_manager.occupancy_map.values():
		if "survivor_resource" in unit:
			survivors.append(unit)

	if survivors.is_empty():
		return null

	var best_target = null
	var best_score = -1.0 # Depends on metric

	var boss_pos = grid_manager.local_to_grid(boss_node.position)

	if priority == "Closest":
		var min_dist = 999999
		for s in survivors:
			var s_pos = grid_manager.local_to_grid(s.position)
			var dist = _manhattan_distance(boss_pos, s_pos)
			if dist < min_dist:
				min_dist = dist
				best_target = s
	elif priority == "Most Injured":
		var max_injuries = -1
		for s in survivors:
			var injuries = 0
			var res = s.survivor_resource
			if res and res.body_parts:
				for part in res.body_parts.values():
					if part.is_injured:
						injuries += 1

			if injuries > max_injuries:
				max_injuries = injuries
				best_target = s
	else:
		# Default to first found
		best_target = survivors[0]

	return best_target

func _get_next_step(start_pos: Vector2i, target_pos: Vector2i) -> Vector2i:
	# Simple Step-Toward logic (Manhattan)
	# Find neighbor that reduces distance to target_pos
	# But must be valid (not occupied, except maybe by target - wait, we can't move ONTO target)
	# And within grid bounds.

	var neighbors = [
		start_pos + Vector2i(0, 1),
		start_pos + Vector2i(0, -1),
		start_pos + Vector2i(1, 0),
		start_pos + Vector2i(-1, 0)
	]

	var best_neighbor = start_pos
	var min_dist = _manhattan_distance(start_pos, target_pos)

	for n in neighbors:
		if not grid_manager.is_valid_coord(n):
			continue

		# Check occupancy
		# We cannot move into an occupied tile
		if grid_manager.occupancy_map.has(n):
			continue

		var dist = _manhattan_distance(n, target_pos)
		if dist < min_dist:
			min_dist = dist
			best_neighbor = n

	return best_neighbor

func _manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

func _spawn_boss(boss_id: String):
	if not grid_manager:
		return

	boss_node = Node2D.new()
	boss_node.name = boss_id

	# Visuals (3x3 tiles = 192x192)
	var color_rect = ColorRect.new()
	color_rect.size = Vector2(180, 180) # Slightly smaller
	color_rect.color = Color.RED
	color_rect.position = Vector2(-90, -90)
	boss_node.add_child(color_rect)

	# Assign a mock AI deck
	var mock_card = AICardResource.new()
	mock_card.card_name = "Claw Sweep"
	mock_card.targeting_priority = "Closest"

	# Script for Boss Data
	boss_node.set_script(load("res://scripts/UnitEntity.gd"))
	boss_node.ai_deck = [mock_card]
	boss_node.integrity = 10

	# Mock Hit Location Deck
	var hl = HitLocationResource.new()
	hl.location_name = "Exposed Ribs"
	boss_node.hit_location_deck = [hl, hl, hl]

	# Add to GridManager
	grid_manager.add_child(boss_node)

	# Set Position (Center)
	var spawn_pos = Vector2i(12, 12)
	boss_node.position = grid_manager.grid_to_local(spawn_pos) + Vector2(grid_manager.TILE_SIZE/2.0, grid_manager.TILE_SIZE/2.0)

func check_game_state():
	# Check Victory
	if boss_node and "integrity" in boss_node and boss_node.integrity <= 0:
		_on_combat_log("VICTORY! Boss defeated.")
		if GameManager:
			GameManager.change_phase("SILT")
		return

	# Check Defeat
	var alive_survivors = 0
	for unit in grid_manager.occupancy_map.values():
		if "survivor_resource" in unit and unit.survivor_resource:
			# If unit is still on grid, it's alive (we assume dead are removed or handled)
			# But CombatResolver just logs death. We need to handle removal.
			alive_survivors += 1

	if alive_survivors == 0:
		_on_combat_log("GAME OVER! All survivors dead.")
		# Return to Main Menu logic (omitted, just log for now or change scene to Main)

func _on_combat_log(msg):
	if trial_ui:
		trial_ui.log_message(msg)
	else:
		print(msg)

func _on_survivor_died(survivor):
	_on_combat_log(survivor.survivor_name + " has perished.")
	# Find and remove the unit
	for unit in grid_manager.occupancy_map.values():
		if "survivor_resource" in unit and unit.survivor_resource == survivor:
			grid_manager.occupancy_map.erase(grid_manager.local_to_grid(unit.position))
			unit.queue_free()
			break
	check_game_state()
