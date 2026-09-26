extends CanvasLayer

@onready var inventorybox: Control = $MarginContainer/inventorybox

var max_slots: int = 6
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
