extends AnimatedSprite2D

var thrower: Node2D
var start_pos: Vector2
var target_pos: Vector2
var t: float = 0.0
var returning: bool = false
var speed: float = 1.5
var spin_speed: float = 15.0

func _ready() -> void:
	play() # Play animation if it has one
	
	# Connect to the Area2D collision
	var area = get_node_or_null("Area2D")
	if area:
		area.body_entered.connect(_on_body_entered)

func throw(from: Node2D, target: Vector2) -> void:
	thrower = from
	start_pos = from.global_position
	target_pos = target
	global_position = start_pos
	returning = false
	t = 0.0

func _physics_process(delta: float) -> void:
	rotation += spin_speed * delta
	
	if not returning:
		t += delta * speed
		if t >= 0.3:
			t = 0.3
			returning = true
		
		# Ease out
		var ease_t = 1.0 - pow(1.0 - t, 2)
		global_position = start_pos.lerp(target_pos, ease_t)
	else:
		t -= delta * speed
		if t <= 0.0 or (is_instance_valid(thrower) and global_position.distance_to(thrower.global_position) < 20.0):
			queue_free()
			return
			
		# Return to the dynamic thrower position
		if is_instance_valid(thrower):
			start_pos = thrower.global_position
			
		var ease_t = 1.0 - pow(1.0 - t, 2)
		global_position = start_pos.lerp(target_pos, ease_t)

func _on_body_entered(body: Node2D) -> void:
	if body == thrower:
		return
	
	if body.has_method("take_damage"):
		# Check if it's the boss
		if body.name != "Player" and body.name != "Player2":
			body.take_damage(1)
			returning = true # Bounce back on hit!
