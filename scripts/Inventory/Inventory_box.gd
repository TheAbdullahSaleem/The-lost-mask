extends Panel
class_name InventorySlot

@onready var item_icon: TextureRect = $item_image
@onready var item_count: Label = $Item_count

func _ready() -> void:
	add_to_group("inventory_slots")

func display_item(texture: Texture2D, amount: int) -> void:
	if amount <= 0:
		item_icon.texture = null
		item_count.text = ""
	else:
		item_icon.texture = texture
		
		# CHECK: If the texture file path contains "pickaxe", hide the text number!
		if texture.resource_path.contains("pickaxe"):
			item_count.text = ""
		else:
			item_count.text = str(amount)
