extends Node2D

# ── Inventory Data ────────────────────────────────────────────────────────────
var inventory: Dictionary = {
	"dirt": 0,
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
	"diamond": preload("res://assets/sprites/others/pickaxe.png"),   # placeholder until diamond sprite made
	"dynamite": preload("res://assets/sprites/charcoal/charcoal.png"), # placeholder until dynamite sprite made
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

const inventory_scene = preload("res://scenes/Inventory/canvas_layer.tscn")

# ── Mining ────────────────────────────────────────────────────────────────────
@onready var blocks: TileMapLayer = $blocks

# Source 0=dirt, 1=charcoal, 2=iron, 3=stone (NOT mineable), 4=grass→drops dirt
const STONE_SOURCE_ID := 3

const BLOCK_SCENES: Dictionary = {
	0: "res://scenes/blocks/dirt.tscn",
	1: "res://scenes/blocks/charcoal.tscn",
	2: "res://scenes/blocks/stone.tscn",   # iron uses stone break anim
	4: "res://scenes/blocks/dirt.tscn",    # grass uses dirt break anim
}

const BREAK_ANIM_PREFIX: Dictionary = {
	0: "dirt",
	1: "charcoal",
	2: "stone",
	4: "dirt",
}

# What item each source_id drops into inventory
const BLOCK_DROP: Dictionary = {
	0: "dirt",
	1: "charcoal",
	2: "iron",
	4: "dirt",   # grass drops dirt
}

var _active_tiles: Dictionary = {}


# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	spawn_inventory()


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

		var sprite: AnimatedSprite2D = block_instance.get_node("sprite")
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
