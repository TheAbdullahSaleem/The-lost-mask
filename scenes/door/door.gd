extends Node2D

@export var target_scene_path: String = "res://scenes/arena/arena1.tscn"
var unlocked: bool = true

@onready var area: Area2D = $Area2D
var interact_label: Label
var player_nearby: bool = false
var is_transitioning: bool = false

func _ready() -> void:
	interact_label = Label.new()
	interact_label.text = "[E]"
	interact_label.visible = false
	interact_label.top_level = true
	
	# Try to load custom font
	var custom_font = get_custom_font()
	if custom_font:
		interact_label.add_theme_font_override("font", custom_font)
		
	# Force it to be an appropriate size
	interact_label.add_theme_font_size_override("font_size", 14)
	add_child(interact_label)
	
	# Connect the Area2D signals
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if player_nearby and interact_label.visible and not is_transitioning:
		var offset_x = -interact_label.size.x / 2.0
		var offset_y = -60.0
		interact_label.global_position = global_position + Vector2(offset_x, offset_y)
		
func is_locked() -> bool:
	if Global.boss1_defeated and target_scene_path.ends_with("arena1.tscn"):
		return true
	if Global.boss2_defeated and target_scene_path.ends_with("arena2.tscn"):
		return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if not player_nearby or is_transitioning or is_locked():
		return
	
	if event is InputEventKey and event.keycode == KEY_E and event.pressed and not event.echo:
		transition_to_arena()

func transition_to_arena() -> void:
	if unlocked:
		is_transitioning = true
		interact_label.visible = false
		
		var ins = AudioStreamPlayer.new()
		ins.stream = preload("res://assets/sounds/interact.mp3")
		add_child(ins)
		ins.play()
		
		# 1. Create a CanvasLayer to ensure the black fade covers the UI
		var fade_layer = CanvasLayer.new()
		fade_layer.layer = 100 # Put it on top of absolutely everything
		add_child(fade_layer)
		
		# 2. Create the Black Rect
		var color_rect = ColorRect.new()
		color_rect.color = Color(0, 0, 0, 0) # Start fully transparent
		color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT) # Cover entire screen
		fade_layer.add_child(color_rect)
		
		# 3. Tween the alpha to 1.0 (Solid Black) over 1 second
		var tween = create_tween()
		tween.tween_property(color_rect, "color:a", 1.0, 1.0)
		
		# 4. Wait for the fade to finish, then save and change scenes!
		await tween.finished
		
		# Force save the current world state BEFORE loading the new scene!
		var world = get_tree().current_scene
		if world and world.has_method("force_save"):
			world.force_save()
			
		get_tree().change_scene_to_file(target_scene_path)
	
func _on_body_entered(body: Node2D) -> void:
	if (body.name == "Player" or body.name == "Player2") and unlocked:
		player_nearby = true
		if not is_transitioning:
			if is_locked():
				interact_label.text = "[LOCKED]"
				interact_label.add_theme_color_override("font_color", Color(1, 0, 0, 1))
			else:
				interact_label.text = "[E]"
			interact_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player" or body.name == "Player2":
		player_nearby = false
		interact_label.visible = false

# Helper to load your font folder automatically
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
