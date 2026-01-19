class_name UnitEntity
extends Node2D

var survivor_resource: SurvivorResource = null
var ai_deck: Array = []
var hit_location_deck: Array = []
var integrity: int = 10

func get_grid_pos() -> Vector2i:
	var tile_size = 64
	var p = get_parent()
	if p and "TILE_SIZE" in p:
		tile_size = p.TILE_SIZE

	if tile_size <= 0:
		tile_size = 64

	return Vector2i(floor(position.x / tile_size), floor(position.y / tile_size))

func set_grid_pos(pos: Vector2i):
	var tile_size = 64
	var p = get_parent()
	if p and "TILE_SIZE" in p:
		tile_size = p.TILE_SIZE

	position = Vector2(pos.x * tile_size, pos.y * tile_size)
