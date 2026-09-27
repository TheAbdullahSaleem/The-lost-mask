extends Area2D

var active_player: Node2D = null
var label: Label = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	label = Label.new()
	label.text = "Press [E] to open"
	label.visible = false
	label.top_level = true
	label.add_theme_font_size_override("font_size", 12)
	add_child(label)

func is_cage_present() -> bool:
	if not is_inside_tree(): return false
	var cage = get_tree().current_scene.get_node_or_null("crafting table/cage")
	return is_instance_valid(cage) and cage.modulate.a > 0.1

func _process(delta: float) -> void:
	if is_cage_present():
		label.visible = false
		return
		
	if active_player:
		label.visible = true
		var offset_x = -label.size.x / 2.0
		var offset_y = -40.0
		label.global_position = global_position + Vector2(offset_x, offset_y)
	else:
		label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if is_cage_present():
		return
		
	if active_player and label.visible:
		if event is InputEventKey and event.keycode == KEY_E and event.pressed and not event.echo:
			label.visible = false
			
			var ts = AudioStreamPlayer.new()
			ts.stream = preload("res://assets/sounds/treasure.mp3")
			add_child(ts)
			ts.play()
			
			# Camera shake
			if active_player and active_player.has_method("shake_screen"):
				active_player.shake_screen(15.0, 3.0)
			active_player = null
			
			# Start video sequence
			var canvas = CanvasLayer.new()
			canvas.layer = 120
			get_tree().current_scene.add_child(canvas)
			
			var bg = ColorRect.new()
			bg.color = Color(0, 0, 0, 1)
			bg.set_anchors_preset(Control.PRESET_FULL_RECT)
			canvas.add_child(bg)
			
			var video = VideoStreamPlayer.new()
			video.set_anchors_preset(Control.PRESET_FULL_RECT)
			video.expand = true
			video.stream = load("res://assets/video/video.ogv")
			canvas.add_child(video)
			
			video.play()
			
			# Wait until the video is completely finished playing
			await video.finished
			
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		active_player = body

func _on_body_exited(body: Node2D) -> void:
	if body == active_player:
		active_player = null
		label.visible = false
