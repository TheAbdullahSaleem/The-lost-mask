extends CharacterBody2D
@export var speed = 50.0
@export var max_health: int = 20

var target :CharacterBody2D = null
var charging: bool = false
var started: bool = false
var current_health: int = 20

@onready var bossanim: AnimatedSprite2D = $Sprite2D
@onready var chargeanim: AnimatedSprite2D = $charge
@onready var Player: CharacterBody2D = $"../Player"
@onready var Blocks: TileMapLayer = $"../Blocks"

var health_bar_container: Node2D
var health_bar_sprite: Node2D

func _ready():
	current_health = max_health
	
	# Use the user's custom boss_health scene
	var health_scene = load("res://scenes/boss_health.tscn")
	if health_scene:
		health_bar_container = health_scene.instantiate()
		add_child(health_bar_container)
		health_bar_container.position = Vector2(0, -250)
		health_bar_container.z_index = 100
		
		# Try to find the user's AnimatedSprite2D or Sprite2D inside their scene
		for child in health_bar_container.get_children():
			if child is AnimatedSprite2D or child is Sprite2D:
				health_bar_sprite = child
				break
				
		# Fallback just in case the scene is empty (not fully saved)
		if not health_bar_sprite:
			health_bar_sprite = Sprite2D.new()
			var tex = load("res://assets/sprites/others/boss_health.png")
			if tex:
				health_bar_sprite.texture = tex
				health_bar_sprite.vframes = 4
				health_bar_sprite.hframes = 1
			health_bar_container.add_child(health_bar_sprite)
			
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

func update_health_bar() -> void:
	if health_bar_sprite:
		var total_frames = 4
		if health_bar_sprite is Sprite2D and health_bar_sprite.texture:
			total_frames = health_bar_sprite.vframes * health_bar_sprite.hframes
		elif health_bar_sprite is AnimatedSprite2D and health_bar_sprite.sprite_frames:
			total_frames = health_bar_sprite.sprite_frames.get_frame_count("default")
			
		var damage_ratio = 1.0 - (float(current_health) / float(max_health))
		var frame_idx = int(damage_ratio * (total_frames - 1))
		
		# Animate or set frame based on node type
		if health_bar_sprite is AnimatedSprite2D:
			health_bar_sprite.frame = clamp(frame_idx, 0, total_frames - 1)
		elif health_bar_sprite is Sprite2D:
			health_bar_sprite.frame = clamp(frame_idx, 0, total_frames - 1)

func take_damage(amount: int = 1) -> void:
	current_health -= amount
	current_health = clamp(current_health, 0, max_health)
	update_health_bar()
	
	if current_health <= 0:
		queue_free() # Defeat boss
		
		
