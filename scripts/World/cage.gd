extends Sprite2D

@onready var area: Area2D = $Area2D
var note_label: Label
var static_body: StaticBody2D

var active_player: Node2D = null

func _ready() -> void:
	# Add solid collision to prevent player from passing
	static_body = StaticBody2D.new()
	var collision_shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(32, 32) # Approx cage size
	collision_shape.shape = rect
	static_body.add_child(collision_shape)
	add_child(static_body)

	# Setup the note label
	note_label = Label.new()
	note_label.text = "The treasure is locked"
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
		# Center the label above the player's head
		var offset_x = -note_label.size.x / 2.0
		var offset_y = -60.0
		note_label.global_position = active_player.global_position + Vector2(offset_x, offset_y)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.name == "Player2":
		active_player = body
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
