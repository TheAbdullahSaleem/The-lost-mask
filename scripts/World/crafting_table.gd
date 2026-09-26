extends Node2D

@onready var area: Area2D = $Area2D
@onready var interact_label: Label = $InteractLabel

var player_nearby: bool = false
var _player_ref: CharacterBody2D = null
var crafting_ui_scene: PackedScene = preload("res://scenes/UI/crafting_ui.tscn")
var crafting_ui_instance: CanvasLayer = null


func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if not player_nearby:
		return
	if event is InputEventKey and event.keycode == KEY_E and event.pressed and not event.echo:
		if crafting_ui_instance == null:
			_open_crafting_ui()


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		_player_ref = body
		player_nearby = true
		interact_label.visible = true


func _on_body_exited(body: Node) -> void:
	if body is CharacterBody2D:
		_player_ref = null
		player_nearby = false
		interact_label.visible = false
		_close_crafting_ui()


func _open_crafting_ui() -> void:
	crafting_ui_instance = crafting_ui_scene.instantiate()
	# Walk up the tree to find the World node (has 'inventory' property)
	var world_node: Node = get_parent()
	while world_node != null and not world_node.get("inventory"):
		world_node = world_node.get_parent()
	crafting_ui_instance.world = world_node
	crafting_ui_instance.tree_exiting.connect(_on_ui_closed)
	get_tree().root.add_child(crafting_ui_instance)
	interact_label.visible = false


func _close_crafting_ui() -> void:
	if crafting_ui_instance != null:
		crafting_ui_instance.queue_free()
		crafting_ui_instance = null


func _on_ui_closed() -> void:
	crafting_ui_instance = null
	if player_nearby:
		interact_label.visible = true
