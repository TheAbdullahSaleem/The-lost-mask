extends SceneTree
func _init():
    var img = Image.load_from_file("res://assets/sprites/others/progress_bar_track.png")
    var file = FileAccess.open("res://img_size.txt", FileAccess.WRITE)
    file.store_string(str(img.get_size()))
    file.close()
    quit()
