extends CharacterBody2D

@export_category("Movement")
@export var move_speed: float = 200.0
@export var acceleration: float = 1400.0
@export var friction: float = 1800.0
@export var jump_velocity: float = -280.0

@export_category("Mining")
@export var mine_time: float = 0.5
@export var mine_reach: float = 2.5
@export var orbit_radius: float = 28.0

@onready var animated_sprite: AnimatedSprite2D = $sprites
@onready var pickaxe: Node2D = $PickaxeIndicator
@onready var progress_bar: AnimatedSprite2D = get_node_or_null("MineProgress") as AnimatedSprite2D

var _mine_timer: float = 0.0
var _mine_direction: String = "down"
var _current_mine_tile: Vector2i = Vector2i(-9999, -9999)
var _target_tile: Vector2i = Vector2i(-9999, -9999)


func _ready() -> void:
	animated_sprite.play("idle")
	if progress_bar:
		progress_bar.visible = false

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_jump()
	handle_movement(delta)
	update_pickaxe()
	handle_mining(delta)
	update_animation()
	move_and_slide()


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta


func handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5


func handle_movement(delta: float) -> void:
<<<<<<< HEAD
	var direction: float = Input.get_axis("left", "right")
=======
	var direction = Input.get_axis("left", "right")

>>>>>>> bc4cd695ba96372a703d15dce43cc7242aebb784
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * move_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)


func update_pickaxe() -> void:
	if not pickaxe:
		return

	var mouse_world: Vector2 = get_global_mouse_position()
	var angle: float = (mouse_world - global_position).angle()
	# Move pickaxe around player in a circle — sprite stays upright
	pickaxe.position = Vector2(orbit_radius, 0.0).rotated(angle)
	pickaxe.rotation = 0.0

	var deg: float = rad_to_deg(angle)
	if deg >= -45.0 and deg < 45.0:
		_mine_direction = "right"
	elif deg >= 45.0 and deg < 135.0:
		_mine_direction = "down"
	elif deg >= 135.0 or deg < -135.0:
		_mine_direction = "left"
	else:
		_mine_direction = "up"

	var world: Node = get_parent()
	if not world:
		return
	var blocks_node: TileMapLayer = world.get_node_or_null("blocks")
	if not blocks_node:
		return

	var pickaxe_tip: Vector2 = global_position + Vector2(orbit_radius, 0.0).rotated(angle)
	var tile: Vector2i = blocks_node.local_to_map(blocks_node.to_local(pickaxe_tip))
	var player_tile: Vector2i = blocks_node.local_to_map(blocks_node.to_local(global_position))
	var dist: float = Vector2(tile).distance_to(Vector2(player_tile))

	if dist <= mine_reach and world.has_method("is_mineable") and world.is_mineable(tile):
		_target_tile = tile
	else:
		_target_tile = Vector2i(-9999, -9999)


func handle_mining(delta: float) -> void:
	var world: Node = get_parent()
	if not world or not world.has_method("is_mineable"):
		return

	if not Input.is_action_pressed("mine") or _target_tile == Vector2i(-9999, -9999):
		_mine_timer = 0.0
		_current_mine_tile = Vector2i(-9999, -9999)
		if progress_bar:
			progress_bar.visible = false
		return

	if _target_tile != _current_mine_tile:
		_mine_timer = 0.0
		_current_mine_tile = _target_tile

	_mine_timer += delta

	if progress_bar:
		progress_bar.visible = true
		# Map 0.0→1.0 progress to frame 0→4
		progress_bar.frame = int((_mine_timer / mine_time) * 4.0)

	if _mine_timer >= mine_time:
		_mine_timer = 0.0
		_current_mine_tile = Vector2i(-9999, -9999)
		if progress_bar:
			progress_bar.visible = false
		world.mine_tile(_target_tile, _mine_direction)


func update_animation() -> void:
	# 1. Check airborne state first (highest priority)
	if not is_on_floor():
		if velocity.y < 0:
			play_animation("Jump")     # Going up (Note: Capital 'J' to match your naming)
		else:
			play_animation("falling")  # Going down
	
	# 2. Ground state
	else:
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
