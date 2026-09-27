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

func _process(delta: float) -> void:
	if active_player and label.visible:
		var offset_x = -label.size.x / 2.0
		var offset_y = -40.0
		label.global_position = global_position + Vector2(offset_x, offset_y)

func _unhandled_input(event: InputEvent) -> void:
	if active_player and label.visible:
		if event is InputEventKey and event.keycode == KEY_E and event.pressed and not event.echo:
			label.visible = false
			# Camera shake
			if active_player and active_player.has_method("shake_screen"):
				active_player.shake_screen(15.0, 3.0)
			active_player = null
			
			# Wait for video placeholder
			var canvas = CanvasLayer.new()
			canvas.layer = 120
			get_tree().current_scene.add_child(canvas)
			
			var bg = ColorRect.new()
			bg.color = Color(0, 0, 0, 1)
			bg.set_anchors_preset(Control.PRESET_FULL_RECT)
			canvas.add_child(bg)
			
			var lbl = Label.new()
			lbl.text = "[ FULLSCREEN VIDEO PLAYS HERE ]"
			lbl.add_theme_font_size_override("font_size", 48)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
			canvas.add_child(lbl)
			
			await get_tree().create_timer(3.0).timeout
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		active_player = body
		label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body == active_player:
		active_player = null
		label.visible = false

