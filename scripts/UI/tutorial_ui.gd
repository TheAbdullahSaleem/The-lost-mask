extends CanvasLayer

var messages: Array[String] = [
	"⛏️ Use Left Click to mine blocks",
	"🧱 Use Right Click to place selected blocks",
	"🔢 Use numbers 1-6 or scroll wheel to select items",
	"⬆️ Press Tab to teleport back to the surface"
]

@onready var label: Label = $MarginContainer/Label
var current_msg_idx: int = 0

func _ready() -> void:
	label.modulate.a = 0.0
	_show_next_message()

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
