extends Node2D

@export var inventory: Dictionary = {
	"dirt": 0,
	"stone": 0,
	"charcoal": 0,
	"iron": 0,
	"pickaxe": 0,
}

var inventory_material: Dictionary = {
	"dirt": preload("res://assets/sprites/dirt/dirt.png"),
	"stone": preload("res://assets/sprites/stone/stone.png"),
	"charcoal": preload("res://assets/sprites/charcoal/charcoal.png"),
	"iron": preload("res://assets/sprites/iron/iron.png"),
	"pickaxe": preload("res://assets/sprites/others/pickaxe.png"),
}

# A dictionary mapping item keys to slot positions (0 to 5)
var item_slot_mapping: Dictionary = {
	"pickaxe": 0,
	"dirt": 1,
	"stone": 2,
	"charcoal": 3,
	"iron": 4
}

const inventory_scene = preload("res://scenes/Inventory/canvas_layer.tscn")
@onready var blocks: TileMapLayer = $blocks

const STONE_SOURCE_ID := 3
const BLOCK_SCENES: Dictionary = {
	0: "res://scenes/blocks/dirt.tscn",
	1: "res://scenes/blocks/charcoal.tscn",
	2: "res://scenes/blocks/stone.tscn",
	4: "res://scenes/blocks/dirt.tscn",
}

const BREAK_ANIM_PREFIX: Dictionary = {
	0: "dirt",
	1: "charcoal",
	2: "stone",
	4: "dirt",
}

var _active_tiles: Dictionary = {}

func _ready() -> void:
	# Automatically spawn the UI layer onto the scene tree when the world starts
	spawn_inventory()
	
	# Wait 5 seconds as requested, then add a test item
	await get_tree().create_timer(5.0).timeout 
	change_inventory_item("pickaxe", 1)
	await get_tree().create_timer(5.0).timeout 
	change_inventory_item("dirt", 1)
	await get_tree().create_timer(5.0).timeout 
	change_inventory_item("stone", 1)
	await get_tree().create_timer(5.0).timeout 
	change_inventory_item("iron", 1)
	await get_tree().create_timer(5.0).timeout 
	change_inventory_item("charcoal", 1)

func is_mineable(tile_coords: Vector2i) -> bool:
	var source_id: int = blocks.get_cell_source_id(tile_coords)
	if source_id == -1 or source_id == STONE_SOURCE_ID:
		return false
	return true

func mine_tile(tile_coords: Vector2i, direction: String) -> void:
	var source_id: int = blocks.get_cell_source_id(tile_coords)
	if source_id == -1 or source_id == STONE_SOURCE_ID or _active_tiles.has(tile_coords):
		return

	_active_tiles[tile_coords] = true
	blocks.erase_cell(tile_coords)

	if BLOCK_SCENES.has(source_id):
		var block_scene: PackedScene = load(BLOCK_SCENES[source_id])
		var block_instance: Node2D = block_scene.instantiate()
		add_child(block_instance)
		block_instance.global_position = blocks.to_global(blocks.map_to_local(tile_coords))

		var sprite: AnimatedSprite2D = block_instance.get_node("sprite")
		var anim_prefix: String = BREAK_ANIM_PREFIX.get(source_id, "dirt")
		var anim_name: String = anim_prefix + "_break_" + direction

		if not sprite.sprite_frames.has_animation(anim_name):
			anim_name = anim_prefix + "_break_down"

		sprite.play(anim_name)
		await sprite.animation_looped
		block_instance.queue_free()

	_active_tiles.erase(tile_coords)

func change_inventory_item(block_name: String, quantity: int) -> void:
	block_name = block_name.to_lower()
	if inventory.has(block_name):
		inventory[block_name] += quantity
		
		# Locate the inventory slot matching this block type
		if item_slot_mapping.has(block_name):
			var slot_id = item_slot_mapping[block_name]
			var texture = inventory_material[block_name]
			var current_amount = inventory[block_name]
			
			# Fire a global group call to update the UI layer safely!
			get_tree().call_group("inventory_ui", "update_slot_ui", slot_id, texture, current_amount)

func spawn_inventory() -> void:
	var inv_instance = inventory_scene.instantiate()
	add_child(inv_instance)
	print("Inventory UI canvas layer added successfully!")
