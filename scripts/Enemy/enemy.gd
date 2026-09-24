extends CharacterBody2D
@export var speed = 100.0
var target :CharacterBody2D = null

func _physics_process(delta: float) -> void:
	if target:
		var direction = global_position.direction_to(target.global_position)
		velocity = direction * speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO

func _on_detection_zone_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		target = body


func _on_detection_zone_body_exited(body: Node2D) -> void:
	if body == target:
		target = null
		
		
