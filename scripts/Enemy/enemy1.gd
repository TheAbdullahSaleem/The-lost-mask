extends CharacterBody2D
@export var speed = 100.0
@export var max_health: int = 30

var target :CharacterBody2D = null
var charging: bool = false
var started: bool = false
var current_health: int = 20

@onready var bossanim: AnimatedSprite2D = $Sprite2D
@onready var chargeanim: AnimatedSprite2D = $charge
@onready var Player: CharacterBody2D = $"../Player"
@onready var Blocks: TileMapLayer = $"../Blocks"

var health_bar_sprite: Sprite2D

func _ready():
	current_health = max_health
	
	health_bar_sprite = Sprite2D.new()
	var tex = load("res://assets/sprites/others/boss_health.png")
	if tex:
		health_bar_sprite.texture = tex
		health_bar_sprite.vframes = 9
		health_bar_sprite.hframes = 3
		
	# Float it above the boss
	health_bar_sprite.position = Vector2(0, -100)
	health_bar_sprite.z_index = 100
	add_child(health_bar_sprite)
			
	update_health_bar()
	
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
	
	# Check for player collision to deal damage
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.name == "Player":
			if collider.has_method("take_damage"):
				collider.take_damage(1)
			if collider.has_method("shake_screen"):
				collider.shake_screen()

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
		if velocity.x == 0:
			bossanim.play("idle")
		elif velocity.x < 0:
			bossanim.play("left")
		else:
			bossanim.play("right")
	else:
		chargeanim.visible = true
		chargeanim.process_mode = Node.PROCESS_MODE_INHERIT
		bossanim.play("charge")
		chargeanim.play("charge")


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		print("player entered")

func update_health_bar() -> void:
	if health_bar_sprite and health_bar_sprite.texture:
		var total_frames = health_bar_sprite.vframes * health_bar_sprite.hframes
		var damage_ratio = 1.0 - (float(current_health) / float(max_health))
		var frame_idx = int(damage_ratio * (total_frames - 1))
		health_bar_sprite.frame = clamp(frame_idx, 0, total_frames - 1)

func take_damage(amount: int = 1) -> void:
	current_health -= amount
	current_health = clamp(current_health, 0, max_health)
	update_health_bar()
	
	if current_health <= 0:
		queue_free() # Defeat boss
		
		
