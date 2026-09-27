extends CanvasLayer

@onready var inventorybox: Control = $MarginContainer/inventorybox

var max_slots: int = 8
var active_slot_index: int = 0

func _ready() -> void:
	highlight_active_slot()
	# Register the overall layer container to its own group so the world can find it
	add_to_group("inventory_ui")
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			active_slot_index = (active_slot_index - 1 + max_slots) % max_slots
			highlight_active_slot()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			active_slot_index = (active_slot_index + 1) % max_slots
			highlight_active_slot()
	elif event is InputEventKey and event.is_pressed():
		if event.keycode >= KEY_1 and event.keycode < KEY_1 + max_slots:
			active_slot_index = event.keycode - KEY_1
			highlight_active_slot()

func highlight_active_slot() -> void:
	var slots = inventorybox.get_children()
	for i in range(slots.size()):
		if i == active_slot_index:
			slots[i].modulate = Color(1.5, 1.5, 1.5)
		else:
			slots[i].modulate = Color(1, 1, 1)

# This updates a targeted slot inside this specific instance tree
func update_slot_ui(slot_index: int, texture: Texture2D, amount: int) -> void:
	var slots = inventorybox.get_children()
	if slot_index >= 0 and slot_index < slots.size():
		slots[slot_index].display_item(texture, amount)

func update_equipped_tool(texture: Texture2D) -> void:
	var tool_image = get_node_or_null("ToolIndicatorContainer/Panel/ToolImage")
	if tool_image:
		tool_image.texture = texture

func get_heart_texture(is_full: bool) -> Texture2D:
	var dir = DirAccess.open("res://assets/sprites/others/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not file_name.ends_with(".import"):
				var lower = file_name.to_lower()
				if "heart" in lower:
					if is_full and "full" in lower:
						return load("res://assets/sprites/others/" + file_name) as Texture2D
					elif not is_full and "empty" in lower:
						return load("res://assets/sprites/others/" + file_name) as Texture2D
			file_name = dir.get_next()
			
	# FALLBACK: If user hasn't added the heart images yet (or named them wrong),
	# generate a colored square so the UI still shows up.
	var fallback = PlaceholderTexture2D.new()
	fallback.size = Vector2(40, 40)
	return fallback

func update_health(current: int, maximum: int) -> void:
	var heart_full = get_heart_texture(true)
	var heart_empty = get_heart_texture(false)
	
	var hearts_container = get_node_or_null("HealthContainer/HBoxContainer")
	if not hearts_container:
		return
		
	var heart_nodes = hearts_container.get_children()
	for i in range(heart_nodes.size()):
		var is_full_heart = (i < current)
		heart_nodes[i].texture = heart_full if is_full_heart else heart_empty
		
		# Only tint if it's our generated fallback square
		if heart_nodes[i].texture is PlaceholderTexture2D:
			heart_nodes[i].modulate = Color(1, 0.2, 0.2) if is_full_heart else Color(0.3, 0.3, 0.3)
		else:
			heart_nodes[i].modulate = Color(1, 1, 1)
