extends "res://tests/gut_test.gd"

var GridManager = load("res://scripts/GridManager.gd")
var grid_manager

func before_each():
	grid_manager = GridManager.new()
	add_child(grid_manager)

func after_each():
	grid_manager.queue_free()

func test_clicking_selected_unit_deselects():
	var mock_unit = Node.new()
	mock_unit.name = "MockUnit"
	func get_grid_pos():
		return Vector2i(5, 5)
	mock_unit.get_grid_pos = get_grid_pos

	grid_manager.add_child(mock_unit)
	grid_manager._refresh_occupancy_map()

	var unit_pos = mock_unit.get_grid_pos()

	# Simulate first click to select
	grid_manager._handle_grid_input(grid_manager.grid_to_local(unit_pos) + Vector2(1,1))
	assert_eq(grid_manager.selected_unit, mock_unit, "Unit should be selected after the first click.")

	# Simulate second click to deselect
	grid_manager._handle_grid_input(grid_manager.grid_to_local(unit_pos) + Vector2(1,1))
	assert_is_null(grid_manager.selected_unit, "Unit should be deselected after the second click.")
