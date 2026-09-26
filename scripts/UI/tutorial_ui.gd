extends CanvasLayer

var messages: Array[String] = [
	"⛏️ Use Left Click to mine blocks",
	"🧱 Use Right Click to place selected blocks",
	"Use numbers 1-6 or scroll wheel to select items",
	"Press Tab to teleport back to the surface"
]

@onready var label: Label = $MarginContainer/Label
var current_msg_idx: int = 0

func _ready() -> void:
	label.modulate.a = 0.0
	
	# Try to load custom font
	var custom_font = get_custom_font()
	if custom_font:
		label.add_theme_font_override("font", custom_font)
		
	_show_next_message()

func get_custom_font() -> Font:
	var dir = DirAccess.open("res://assets/fonts/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not file_name.begins_with(".") and not file_name.ends_with(".import"):
				if file_name.ends_with(".ttf") or file_name.ends_with(".otf") or file_name.ends_with(".tres") or file_name.ends_with(".font"):
					return load("res://assets/fonts/" + file_name) as Font
			file_name = dir.get_next()
	return null

func _show_next_message() -> void:
	if current_msg_idx >= messages.size():
		queue_free()
		return
		
	label.text = messages[current_msg_idx]
	current_msg_idx += 1
	
	var tween = create_tween()
	# Fade in
	tween.tween_property(label, "modulate:a", 1.0, 0.5)
	# Wait
	tween.tween_interval(3.0)
	# Fade out
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	# Pause before next
	tween.tween_interval(0.2)
	
	tween.finished.connect(_show_next_message)
