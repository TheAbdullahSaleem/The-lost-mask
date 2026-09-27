extends Sprite2D

@onready var area: Area2D = $Area2D
var note_label: Label
var static_body: StaticBody2D

var active_player: Node2D = null



func _ready() -> void:

	# Setup the note label
	note_label = Label.new()
	note_label.text = "Find mask to unlock"
	note_label.visible = false
	note_label.top_level = true # Ignore parent scale and transform
	
	# Try to load custom font
	var custom_font = get_custom_font()
	if custom_font:
		note_label.add_theme_font_override("font", custom_font)
		
	# Force it to be small
	note_label.add_theme_font_size_override("font_size", 10)
		
	add_child(note_label)

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if active_player and note_label.visible:
		# Center the label above the player's hea\
		var offset_x = -note_label.size.x / 2.0
		var offset_y = -60.0
		note_label.global_position = active_player.global_position + Vector2(offset_x, offset_y)
		
func _unhandled_input(event: InputEvent) -> void:
	if active_player and Global.has_mask_full:
		if event is InputEventKey and event.keycode == KEY_E and event.pressed and not event.echo:
			# Open the cage
			var cs = AudioStreamPlayer.new()
			cs.stream = preload("res://assets/sounds/cage.mp3")
			get_tree().current_scene.add_child(cs)
			cs.play()
			cs.finished.connect(cs.queue_free)
			
			var tw = create_tween()
			tw.tween_property(self, "modulate:a", 0.0, 1.5)
			tw.tween_callback(self.queue_free)
			active_player = null
			note_label.visible = false

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.name == "Player2":
		active_player = body
		if Global.has_mask_full:
			note_label.text = "Press [E] to unlock"
		else:
			note_label.text = "Find mask to unlock"
		note_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body == active_player:
		active_player = null
		note_label.visible = false

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
