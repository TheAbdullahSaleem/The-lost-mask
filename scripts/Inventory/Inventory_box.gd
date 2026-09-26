extends Panel
class_name InventorySlot

@onready var item_icon: TextureRect = $item_image
@onready var item_count: Label = $Item_count

func _ready() -> void:
	# This automatically adds every panel instance to a global registry group!
	add_to_group("inventory_slots")

func display_item(texture: Texture2D, amount: int) -> void:
	if amount <= 0:
		item_icon.texture = null
		item_count.text = ""
	else:
		item_icon.texture = texture
		item_count.text = str(amount)
