extends Control

func _ready():
	$VBoxContainer/PlayButton.pressed.connect(start_game)
	$VBoxContainer/QuitButton.pressed.connect(quit_game)

func start_game():
	get_tree().change_scene_to_file("res://scenes/world/world.tscn")

func quit_game():
	get_tree().quit()
