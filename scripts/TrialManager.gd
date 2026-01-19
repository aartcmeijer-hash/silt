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

# In a real scene, this would be set or found.
# We will assume GridManager is a sibling.
func _ready():
	# Try to find GridManager
	if get_parent():
		grid_manager = get_parent().get_node_or_null("GridManager")

	if grid_manager:
		grid_manager.move_requested.connect(_on_unit_move_requested)
		_initialize_resources()
	else:
		push_warning("TrialManager: GridManager not found.")

	# Initialize turn states for survivors (if any exist at start)
	start_phase(Phase.PLAYER_PHASE)

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

	if unit in turn_states:
		var state = turn_states[unit]
		if state.can_move:
			# Verify with GridManager if move is valid (GridManager already checked valid_moves,
			# but we should double check if path is clear? GridManager handles that).
			grid_manager.move_unit(unit, target_pos)
			state.can_move = false

			# Check for interactions?
			# The prompt says: "Moving consumes the move; attacking or using an item consumes the act."
			# It also says: "Trigger a signal attack_initiated... when a monster or survivor moves into range and acts."
			# This implies an action is separate. But here we just handled move.
			# If the user wants to attack, that would likely be a different input/method.
			# For now, we just handle the move.

			# Note: If the unit moved adjacent to an enemy, the user might want to attack next.
			# That logic would need another input handler (e.g. clicking on an enemy).
			# For this task, we focus on the structure.

func end_turn():
	if current_phase == Phase.PLAYER_PHASE:
		start_phase(Phase.MONSTER_PHASE)

func request_attack(attacker: Node, target: Node):
	if current_phase != Phase.PLAYER_PHASE:
		return

	if attacker in turn_states:
		var state = turn_states[attacker]
		if state.can_act:
			# Verify target validity/range if needed. For now, we assume caller checked range.
			# (Or we could check adjacency here)
			var attacker_pos = grid_manager.local_to_grid(attacker.position)
			var target_pos = grid_manager.local_to_grid(target.position)

			if _manhattan_distance(attacker_pos, target_pos) <= 1: # Basic range 1 check
				state.can_act = false
				emit_signal("attack_initiated", attacker, target)

func _run_monster_turn():
	if not grid_manager:
		return

	var units = grid_manager.occupancy_map.values()
	var boss_node = null

	# Find Boss
	for unit in units:
		if "ai_deck" in unit and unit.ai_deck is Array and unit.ai_deck.size() > 0:
			boss_node = unit
			break

	if not boss_node:
		# No monster, go back to player phase? Or end game?
		# For now, switch back to player phase to prevent stuck state
		start_phase(Phase.PLAYER_PHASE)
		return

	# Retrieve AI Deck
	var ai_deck = boss_node.ai_deck
	var ai_card = ai_deck[0] # Simple: pick first card

	# Target Selection
	var target = _get_best_target(boss_node, ai_card.targeting_priority)

	if target:
		# Movement: Step-Toward
		var start_pos = grid_manager.local_to_grid(boss_node.position)
		var target_pos = grid_manager.local_to_grid(target.position)

		# We want to be adjacent to target
		if _manhattan_distance(start_pos, target_pos) > 1:
			var next_step = _get_next_step(start_pos, target_pos)
			if next_step != start_pos:
				grid_manager.move_unit(boss_node, next_step)

		# Check if in range to act (assuming range 1 for now or based on card?)
		# Prompt says: "Move the Boss node to the nearest valid tile adjacent to the target"
		# Then "Interaction: Trigger a signal ... when ... acts"
		var current_pos = grid_manager.local_to_grid(boss_node.position)
		var dist = _manhattan_distance(current_pos, grid_manager.local_to_grid(target.position))

		# Assuming range 1 adjacency for attack
		if dist == 1:
			emit_signal("attack_initiated", boss_node, target)

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
