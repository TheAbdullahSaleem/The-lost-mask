extends Node2D

# ── Inventory Data ────────────────────────────────────────────────────────────
var inventory: Dictionary = {
	"dirt": 100,
	"charcoal": 0,
	"iron": 0,
	"diamond": 0,
	"dynamite": 0,
	"pickaxe": 1,
}

var inventory_material: Dictionary = {
	"dirt": preload("res://assets/sprites/dirt/dirt.png"),
	"charcoal": preload("res://assets/sprites/charcoal/charcoal.png"),
	"iron": preload("res://assets/sprites/iron/iron.png"),
	"diamond": preload("res://assets/sprites/diamond/diamond.png"),
	"dynamite": preload("res://assets/sprites/others/dynamite.png"),
	"pickaxe": preload("res://assets/sprites/others/pickaxe.png"),

}

var item_slot_mapping: Dictionary = {
	"dirt": 0,
	"charcoal": 1,
	"iron": 2,
	"diamond": 3,
	"dynamite": 4,
	"pickaxe": 5,
}

var crafted_recipes: Array[String] = [] 

const inventory_scene = preload("res://scenes/Inventory/canvas_layer.tscn")
const tutorial_scene = preload("res://scenes/UI/tutorial_ui.tscn")

# ── Mining & Placing ─────────────────────────────────────────────────────────
@onready var blocks: TileMapLayer = $Blocks

# Source 0=dirt, 1=charcoal, 2=iron, 3=stone (NOT mineable), 4=grass→drops dirt, 5=diamond
const STONE_SOURCE_ID := 3

const PLACEABLE_BLOCKS: Dictionary = {
	"dirt": 0,
	"charcoal": 1,
	"iron": 2,
	"diamond": 5,
}

const BLOCK_SCENES: Dictionary = {
	0: "res://scenes/blocks/dirt.tscn",
	1: "res://scenes/blocks/charcoal.tscn",
	2: "res://scenes/blocks/stone.tscn",   # iron uses stone break anim
	4: "res://scenes/blocks/dirt.tscn",    # grass uses dirt break anim
	5: "res://scenes/blocks/diamond.tscn",
}

const BREAK_ANIM_PREFIX: Dictionary = {
	0: "dirt",
	1: "charcoal",
	2: "stone",
	4: "dirt",
	5: "diamond",
}

# What item each source_id drops into inventory
const BLOCK_DROP: Dictionary = {
	0: "dirt",
	1: "charcoal",
	2: "iron",
	4: "dirt",   # grass drops dirt
	5: "diamond",
}

var _active_tiles: Dictionary = {}
@export var autobreaking: bool = false
@export var break_time: float = 3
@export var tutorial: bool = true

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	# Load persisted inventory if available
	if Global.is_initialized:
		var saved_data = Global.load_inventory()
		inventory = saved_data["inventory"]
		inventory_material = saved_data["inventory_material"]
		
		var player = get_node_or_null("Player")
		if player:
			player.mine_time = saved_data["mine_time"]
			
			# Refill life when returning
			if name == "World":
				player.current_health = player.max_health
				if player.has_method("sync_health_ui"):
					player.sync_health_ui()
			
	# Fix building in Arena by enforcing the proper World TileSet
	if get_tree().current_scene.name != "World":
		var world_scene = load("res://scenes/world/world.tscn")
		if world_scene:
			var temp = world_scene.instantiate()
			var w_blocks = temp.get_node_or_null("Blocks")
			var local_blocks = get_node_or_null("Blocks")
			if w_blocks and local_blocks:
				local_blocks.tile_set = w_blocks.tile_set
			temp.free()
	elif not Global.world_tile_data.is_empty() and blocks:
		# Restore broken land in the World
		blocks.tile_map_data = Global.world_tile_data
		
	spawn_inventory()

	# Manually refresh all inventory slots to reflect loaded blocks
	for item_name in inventory.keys():
		if item_slot_mapping.has(item_name) and inventory_material.has(item_name):
			var slot_id = item_slot_mapping[item_name]
			var count = inventory[item_name]
			var tex = inventory_material[item_name]
			get_tree().call_group("inventory_ui", "update_slot_ui", slot_id, tex, count)
	
	# Spawn tutorial broadcast UI
	if tutorial:
		var tutorial_instance = tutorial_scene.instantiate()
		add_child(tutorial_instance)

func _exit_tree() -> void:
	# Save inventory state when leaving the scene
	var current_mine_time: float = 0.5
	var player = get_node_or_null("Player")
	if player:
		current_mine_time = player.mine_time
		
	if Global:
		Global.save_inventory(inventory, inventory_material, current_mine_time)
		if name == "World" and blocks:
			Global.world_tile_data = blocks.tile_map_data

# ── Placing API ───────────────────────────────────────────────────────────────
func place_block(mouse_global_pos: Vector2) -> void:
	var inv_ui = get_tree().get_first_node_in_group("inventory_ui")
	if not inv_ui:
		return
	
	var active_slot = inv_ui.active_slot_index
	var selected_item_name = ""
	
	# Find which item corresponds to this slot
	for item_name in item_slot_mapping.keys():
		if item_slot_mapping[item_name] == active_slot:
			selected_item_name = item_name
			break
			
	if selected_item_name == "" or not PLACEABLE_BLOCKS.has(selected_item_name):
		return # Item not placeable or not found
		
	# Check if player has the item
	if inventory.get(selected_item_name, 0) <= 0:
		return
		
	# Convert global pos to map coords
	var tile_coords = blocks.local_to_map(blocks.to_local(mouse_global_pos))
	
	# Check if cell is empty
	if blocks.get_cell_source_id(tile_coords) == -1:
		# Place block
		blocks.set_cell(tile_coords, PLACEABLE_BLOCKS[selected_item_name], Vector2i(0, 0))
		# Deduct from inventory
		change_inventory_item(selected_item_name, -1)
	if autobreaking:
		await get_tree().create_timer(break_time).timeout
		mine_tile(tile_coords, "down")

# ── Mining API ────────────────────────────────────────────────────────────────
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

	# ── Erase block immediately ──────────────────────────────────────────────
	blocks.erase_cell(tile_coords)

	# ── Add item to inventory ────────────────────────────────────────────────
	if BLOCK_DROP.has(source_id):
		change_inventory_item(BLOCK_DROP[source_id], 1)

	# ── Play break animation ─────────────────────────────────────────────────
	if BLOCK_SCENES.has(source_id):
		var block_scene: PackedScene = load(BLOCK_SCENES[source_id])
		var block_instance: Node2D = block_scene.instantiate()
		add_child(block_instance)
		block_instance.global_position = blocks.to_global(blocks.map_to_local(tile_coords))

		var sprite: AnimatedSprite2D = block_instance.get_node_or_null("sprite")
		if sprite:
			var anim_prefix: String = BREAK_ANIM_PREFIX.get(source_id, "dirt")
			var anim_name: String = anim_prefix + "_break_" + direction

			if not sprite.sprite_frames.has_animation(anim_name):
				anim_name = anim_prefix + "_break_down"

			sprite.play(anim_name)
			await sprite.animation_looped
		block_instance.queue_free()

	_active_tiles.erase(tile_coords)


# ── Inventory API ─────────────────────────────────────────────────────────────
func change_inventory_item(block_name: String, quantity: int) -> void:
	block_name = block_name.to_lower()
	if not inventory.has(block_name):
		return

	inventory[block_name] += quantity

	if item_slot_mapping.has(block_name):
		var slot_id: int = item_slot_mapping[block_name]
		var texture: Texture2D = inventory_material[block_name]
		var current_amount: int = inventory[block_name]
		get_tree().call_group("inventory_ui", "update_slot_ui", slot_id, texture, current_amount)


func spawn_inventory() -> void:
	var inv_instance = inventory_scene.instantiate()
	add_child(inv_instance)
	
	# Set the initial equipped tool icon
	if inventory_material.has("pickaxe"):
		get_tree().call_group("inventory_ui", "update_equipped_tool", inventory_material["pickaxe"])
