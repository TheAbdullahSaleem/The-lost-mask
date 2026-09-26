extends Panel
@onready var item_icon = $item_image
@onready var item_count = $Item_count


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func display_item(texture: Texture2D,amount:int):
	while item_icon == null or item_count == null:
		print("Waiting")
		await get_tree().process_frame
	if amount<= 0 :
		item_icon.texture = null
		item_count.text = ""
	else:
		item_icon.texture = texture
		item_count.text = str(amount)
		
