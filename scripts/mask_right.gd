extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)
	var t = create_tween().set_loops()
	t.tween_property(self, "position:y", position.y - 10.0, 1.0).set_trans(Tween.TRANS_SINE)
	t.tween_property(self, "position:y", position.y, 1.0).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		Global.has_mask_full = true
		get_tree().call_group("inventory_ui", "show_mask_full")
		queue_free()
