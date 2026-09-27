extends Node

var is_initialized: bool = false
var stored_inventory: Dictionary = {}
var stored_inventory_material: Dictionary = {}
var stored_mine_time: float = 0.5 # Default

var world_tile_data: PackedByteArray = PackedByteArray()
var boss1_defeated: bool = false
var boss2_defeated: bool = false
var has_mask_half: bool = false
var has_mask_full: bool = false

func save_inventory(inv: Dictionary, inv_mat: Dictionary, mine_time: float = 0.5) -> void:
	stored_inventory = inv.duplicate()
	stored_inventory_material = inv_mat.duplicate()
	stored_mine_time = mine_time
	is_initialized = true

func load_inventory() -> Dictionary:
	return {
		"inventory": stored_inventory.duplicate(),
		"inventory_material": stored_inventory_material.duplicate(),
		"mine_time": stored_mine_time
	}
