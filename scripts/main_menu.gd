extends Control

func _ready():
	$VBoxContainer/PlayButton.pressed.connect(start_game)
	$VBoxContainer/QuitButton.pressed.connect(quit_game)
	
	_apply_styles()

func _apply_styles():
	var vbox = $VBoxContainer
	if not vbox: return
	
	# 1. Move everything up and make it smaller/aligned!
	vbox.set_anchors_preset(Control.PRESET_CENTER_TOP)
	vbox.position = Vector2(1152 / 2.0 - 150, 30) # Moved up and perfectly centered (Width 300)
	vbox.custom_minimum_size = Vector2(300, 150)
	vbox.add_theme_constant_override("separation", 15)
	
	# Load the custom font
	var custom_font = load("res://assets/fonts/PixelifySans-Bold.ttf")
	
	# 2. Style the Label
	var title = $VBoxContainer/Label
	if title:
		title.text = "THE LOST MASK"
		title.add_theme_font_size_override("font_size", 64)
		title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2)) # Golden yellow
		title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
		title.add_theme_constant_override("shadow_offset_x", 4)
		title.add_theme_constant_override("shadow_offset_y", 4)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if custom_font:
			title.add_theme_font_override("font", custom_font)
			
	# 3. Style the Buttons
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.12, 0.08, 0.05, 0.95)
	normal_style.border_color = Color(0.8, 0.6, 0.1, 1.0) # Gold border
	normal_style.border_width_bottom = 3
	normal_style.border_width_top = 3
	normal_style.border_width_left = 3
	normal_style.border_width_right = 3
	normal_style.set_corner_radius_all(6)
	normal_style.content_margin_top = 10
	normal_style.content_margin_bottom = 10
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(0.3, 0.2, 0.1, 0.95)
	hover_style.border_color = Color(1.0, 0.9, 0.2, 1.0)
	
	var play_btn = $VBoxContainer/PlayButton
	var quit_btn = $VBoxContainer/QuitButton
	
	for btn in [play_btn, quit_btn]:
		if btn:
			btn.add_theme_font_size_override("font_size", 32)
			btn.add_theme_stylebox_override("normal", normal_style)
			btn.add_theme_stylebox_override("hover", hover_style)
			btn.add_theme_stylebox_override("pressed", normal_style)
			if custom_font:
				btn.add_theme_font_override("font", custom_font)

func start_game():
	Global.is_initialized = false
	Global.world_tile_data.clear()
	Global.boss1_defeated = false
	Global.boss2_defeated = false
	Global.has_mask_half = false
	Global.has_mask_full = false
	get_tree().change_scene_to_file("res://scenes/world/world.tscn")

func quit_game():
	get_tree().quit()
