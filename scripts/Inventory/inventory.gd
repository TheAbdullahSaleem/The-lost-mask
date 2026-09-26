extends CanvasLayer
@onready var inventorybox = $MarginContainer/inventorybox
var max_slots : int = 6
var active_slot_index: int = 0
var slotbar_data = ["","","","","",""]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	highlight_active_slot()
	
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
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func highlight_active_slot():
	var slots = inventorybox.get_children()
	for i in range(slots.size()):
		if i == active_slot_index:
			slots[i].modulate = Color(1.5,1.5,1.5)
		else :
			slots[i].modulate = Color(1,1,1)
		
