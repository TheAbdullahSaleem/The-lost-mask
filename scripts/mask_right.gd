extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)
	var t = create_tween().set_loops()
	t.tween_property(self, "position:y", position.y - 10.0, 1.0).set_trans(Tween.TRANS_SINE)
	t.tween_property(self, "position:y", position.y, 1.0).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		var ps = AudioStreamPlayer.new()
		ps.stream = preload("res://assets/sounds/pickup.mp3")
		get_tree().current_scene.add_child(ps)
		ps.play()
		ps.finished.connect(ps.queue_free)
		
		Global.has_mask_full = true
		get_tree().call_group("inventory_ui", "show_mask_full")
		queue_free()
