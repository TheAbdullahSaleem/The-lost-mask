extends CharacterBody2D

@export_category("Movement")
@export var move_speed: float = 200.0
@export var acceleration: float = 1400.0
@export var friction: float = 1800.0
@export var jump_velocity: float = -280.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	animated_sprite.play("idle")


func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_jump()
	handle_movement(delta)
	update_animation()

	move_and_slide()


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta


func handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity


func handle_movement(delta: float) -> void:
	var direction := Input.get_axis("left", "right")

	if direction != 0:
		velocity.x = move_toward(
			velocity.x,
			direction * move_speed,
			acceleration * delta
		)
	else:
		velocity.x = move_toward(
			velocity.x,
			0.0,
			friction * delta
		)


func update_animation() -> void:
	if abs(velocity.x) > 10.0:
		if velocity.x < 0:
			play_animation("left")
		else:
			play_animation("right")
	else:
		play_animation("idle")


func play_animation(animation_name: String) -> void:
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)
