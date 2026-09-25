extends Node2D

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


func is_mineable(tile_coords: Vector2i) -> bool:
	var source_id: int = blocks.get_cell_source_id(tile_coords)
	if source_id == -1:
		return false
	if source_id == STONE_SOURCE_ID:
		return false
	return true


func mine_tile(tile_coords: Vector2i, direction: String) -> void:
	var source_id: int = blocks.get_cell_source_id(tile_coords)
	if source_id == -1 or source_id == STONE_SOURCE_ID:
		return
	if _active_tiles.has(tile_coords):
		return

	_active_tiles[tile_coords] = true

	# Erase the block immediately — animation is just a visual effect after
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

		# Wait one full loop then clean up
		await sprite.animation_looped
		block_instance.queue_free()

	_active_tiles.erase(tile_coords)
