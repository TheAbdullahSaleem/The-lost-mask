extends CharacterBody2D
@export var speed = 50.0
var target :CharacterBody2D = null
var charging: bool = false
var started: bool = false

@onready var bossanim: AnimatedSprite2D = $Sprite2D
@onready var chargeanim: AnimatedSprite2D = $charge

func _ready():
	var spawntimer = Timer.new()
	add_child(spawntimer)
	spawntimer.start(3)
	await spawntimer.timeout
	bossanim.play("charge")
	chargeanim.play("charge")
	await bossanim.animation_finished
	started = true

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if started:
		if target:
			var direction = global_position.direction_to(target.global_position)
			velocity.x = direction.x * speed
		else:
			velocity.x = 0
		update_animation()
	
	move_and_slide()

func _on_detection_zone_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		target = body


func _on_detection_zone_body_exited(body: Node2D) -> void:
	if body == target:
		target = null
	

func update_animation():
	if not charging:
		chargeanim.visible = false
		chargeanim.process_mode = Node.PROCESS_MODE_DISABLED
		if velocity.x > 0:
			bossanim.play("right")
		elif velocity.x < 0:
			bossanim.play("left")
		else:
			bossanim.play("idle")
	else:
		chargeanim.visible = true
		chargeanim.process_mode = Node.PROCESS_MODE_INHERIT
		bossanim.play("charge")
		chargeanim.play("charge")


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		print("player entered")
		
