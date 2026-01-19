extends Node2D

signal move_requested(unit, target_pos)

# Grid Configuration
const GRID_WIDTH = 24
const GRID_HEIGHT = 24
const TILE_SIZE = 64
const GRID_PIXEL_WIDTH = GRID_WIDTH * TILE_SIZE
const GRID_PIXEL_HEIGHT = GRID_HEIGHT * TILE_SIZE

# Navigation & Occupancy
var occupancy_map = {} # Dictionary[Vector2i, Node]

# Selection & Movement State
var selected_unit: Node = null
var valid_moves: Array[Vector2i] = []
var ghost_pos: Vector2i = Vector2i(-1, -1) # -1, -1 indicates no ghost

# Camera
var camera: Camera2D
var camera_drag_active = false
var camera_last_drag_pos = Vector2()

# Colors for Visualization
const COLOR_GRID = Color(1, 1, 1, 0.2)
const COLOR_MOVE_RANGE = Color(0.2, 0.8, 0.2, 0.3)
const COLOR_GHOST = Color(1, 1, 1, 0.5)

func _ready():
	# Setup Camera
	camera = Camera2D.new()
	add_child(camera)
	camera.position = Vector2(GRID_PIXEL_WIDTH / 2.0, GRID_PIXEL_HEIGHT / 2.0)
	camera.make_current()

	# Initialize occupancy map
	_refresh_occupancy_map()

	queue_redraw()

func _refresh_occupancy_map():
	occupancy_map.clear()
	# In a real scenario, we might scan children or have units register themselves.
	# For now, we assume units are children of this node or managed externally.
	# This is a placeholder for populating the map from existing scene state.
	for child in get_children():
		if child.has_method("get_grid_pos"):
			var pos = child.get_grid_pos()
			occupancy_map[pos] = child

func _unhandled_input(event):
	# Camera Zoom (Mac/Desktop)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_camera(0.9)
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_camera(1.1)
			return

	# Camera Pan (Android/Touch & Desktop Drag)
	if event is InputEventScreenDrag:
		camera.position -= event.relative * camera.zoom
		return
	elif event is InputEventMouseButton:
		# Middle mouse or Right mouse to pan
		if event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			camera_drag_active = event.pressed
			camera_last_drag_pos = event.position
	elif event is InputEventMouseMotion and camera_drag_active:
		var delta = event.position - camera_last_drag_pos
		camera.position -= delta * camera.zoom
		camera_last_drag_pos = event.position
		return

	# Selection & Movement Input (Click/Tap)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_grid_input(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		_handle_grid_input(event.position)

func _zoom_camera(factor):
	if camera:
		camera.zoom *= factor

func _handle_grid_input(screen_pos):
	var global_pos = get_global_mouse_position() # Works for touch too in standard Viewport
	# If using a Camera inside a SubViewport or complex setup, we might need manual conversion.
	# But get_global_mouse_position() usually accounts for Camera2D transforms.

	var grid_pos = local_to_grid(to_local(global_pos))

	if not is_valid_coord(grid_pos):
		_deselect()
		return

	# Check what is at the clicked tile
	var occupied_by = get_unit_at(grid_pos)

	if selected_unit:
		if occupied_by == selected_unit:
			# Clicked self, deselect to allow for a clearer user flow.
			_deselect()
		elif occupied_by != null:
			# Clicked another unit
			_select_unit(occupied_by)
		else:
			# Clicked empty tile
			if grid_pos in valid_moves:
				if ghost_pos == grid_pos:
					# Clicked Ghost again -> CONFIRM MOVE
					emit_signal("move_requested", selected_unit, grid_pos)
				else:
					# Show Ghost
					ghost_pos = grid_pos
					queue_redraw()
			else:
				# Invalid move tile
				_deselect()
	else:
		if occupied_by:
			_select_unit(occupied_by)
		else:
			# Clicked empty space with nothing selected
			_deselect()

func _select_unit(unit):
	selected_unit = unit
	ghost_pos = Vector2i(-1, -1)

	# Calculate valid moves
	valid_moves.clear()
	var move_range = 3 # Default
	if "move_range" in unit:
		move_range = unit.move_range

	# Simple BFS for move range
	valid_moves = _get_valid_moves(unit, move_range)
	queue_redraw()

func _deselect():
	selected_unit = null
	ghost_pos = Vector2i(-1, -1)
	valid_moves.clear()
	queue_redraw()

func get_unit_at(grid_pos: Vector2i) -> Node:
	return occupancy_map.get(grid_pos)

func move_unit(unit, target_pos):
	var current_pos = local_to_grid(unit.position)

	# Update Occupancy
	occupancy_map.erase(current_pos)
	occupancy_map[target_pos] = unit

	# Move Unit Visuals
	unit.position = grid_to_local(target_pos) + Vector2(TILE_SIZE/2.0, TILE_SIZE/2.0)

	# Update Unit Logic (if needed)
	if unit.has_method("set_grid_pos"):
		unit.set_grid_pos(target_pos)

	# Deselect after move
	_deselect()

func _get_valid_moves(unit, range_val):
	var moves: Array[Vector2i] = []
	var start_pos = local_to_grid(unit.position)

	# BFS
	var queue = []
	var visited = {}
	queue.append({ "pos": start_pos, "dist": 0 })
	visited[start_pos] = true

	var head = 0
	while head < queue.size():
		var current = queue[head]
		head += 1
		var c_pos = current["pos"]
		var c_dist = current["dist"]

		if c_dist > 0:
			moves.append(c_pos)

		if c_dist < range_val:
			var neighbors = [
				c_pos + Vector2i(0, 1),
				c_pos + Vector2i(0, -1),
				c_pos + Vector2i(1, 0),
				c_pos + Vector2i(-1, 0)
			]

			for n in neighbors:
				if is_valid_coord(n) and not occupancy_map.has(n) and not visited.has(n):
					visited[n] = true
					queue.append({ "pos": n, "dist": c_dist + 1 })

	return moves

# Grid Helpers
func local_to_grid(local_pos: Vector2) -> Vector2i:
	return Vector2i(floor(local_pos.x / TILE_SIZE), floor(local_pos.y / TILE_SIZE))

func grid_to_local(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE)

func is_valid_coord(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < GRID_WIDTH and pos.y >= 0 and pos.y < GRID_HEIGHT

func _draw():
	# Draw Grid Lines
	for x in range(GRID_WIDTH + 1):
		var start = Vector2(x * TILE_SIZE, 0)
		var end = Vector2(x * TILE_SIZE, GRID_HEIGHT * TILE_SIZE)
		draw_line(start, end, COLOR_GRID)

	for y in range(GRID_HEIGHT + 1):
		var start = Vector2(0, y * TILE_SIZE)
		var end = Vector2(GRID_WIDTH * TILE_SIZE, y * TILE_SIZE)
		draw_line(start, end, COLOR_GRID)

	# Draw Valid Moves
	for move in valid_moves:
		var pos = grid_to_local(move)
		var rect = Rect2(pos, Vector2(TILE_SIZE, TILE_SIZE))
		draw_rect(rect, COLOR_MOVE_RANGE, true)

	# Draw Ghost
	if ghost_pos != Vector2i(-1, -1):
		var pos = grid_to_local(ghost_pos)
		var center = pos + Vector2(TILE_SIZE/2.0, TILE_SIZE/2.0)
		var radius = TILE_SIZE / 3.0
		draw_circle(center, radius, COLOR_GHOST)
		# Or draw a hollow rect
		var rect = Rect2(pos + Vector2(4, 4), Vector2(TILE_SIZE-8, TILE_SIZE-8))
		draw_rect(rect, COLOR_GHOST, false, 4.0)
