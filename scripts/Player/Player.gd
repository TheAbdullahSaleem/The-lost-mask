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

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var pickaxe: Node2D = get_node_or_null("PickaxeIndicator")
@onready var progress_bar: AnimatedSprite2D = get_node_or_null("MineProgress") as AnimatedSprite2D

@export_category("Health")
@export var max_health: int = 3
var current_health: int = 3

var _mine_timer: float = 0.0
var _mine_direction: String = "down"
var _current_mine_tile: Vector2i = Vector2i(-9999, -9999)
var _target_tile: Vector2i = Vector2i(-9999, -9999)
var spawn_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	current_health = max_health
	spawn_position = global_position
	animated_sprite.play("idle")
	if progress_bar:
		progress_bar.visible = false
	
	# Initial health sync (deferred to ensure UI is ready)
	call_deferred("sync_health_ui")

func sync_health_ui() -> void:
	get_tree().call_group("inventory_ui", "update_health", current_health, max_health)

var is_invincible: bool = false
var is_dead: bool = false

func take_damage(amount: int = 1) -> void:
	if is_invincible or is_dead:
		return
		
	current_health -= amount
	current_health = clamp(current_health, 0, max_health)
	sync_health_ui()
	
	if current_health <= 0:
		die()
	else:
		# Apply invincibility frames
		is_invincible = true
		
		# Flash red
		modulate = Color(1, 0, 0, 1)
		await get_tree().create_timer(0.2).timeout
		modulate = Color(1, 1, 1, 1)
		
		await get_tree().create_timer(0.8).timeout
		is_invincible = false

func die() -> void:
	if is_dead: return
	is_dead = true
	# Stop the player from moving
	set_physics_process(false)
	set_process_unhandled_input(false)
	
	# Create a CanvasLayer so the death screen is on top of everything
	var canvas = CanvasLayer.new()
	canvas.layer = 120
	get_tree().current_scene.add_child(canvas)
	
	# Create a black background
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg)
	
	# Create the YOU DIED text
	var label = Label.new()
	label.text = "YOU DIED."
	label.add_theme_color_override("font_color", Color(0.8, 0, 0, 1))
	label.add_theme_font_size_override("font_size", 72)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.modulate.a = 0
	canvas.add_child(label)
	
	# Create a container for the buttons
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.modulate.a = 0
	canvas.add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(300, 100)
	vbox.add_theme_constant_override("separation", 30)
	center.add_child(vbox)
	
	# Button styles
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.12, 0.12, 0.12, 0.95)
	normal_style.border_color = Color(0.8, 0.2, 0.2, 1.0)
	normal_style.border_width_bottom = 4
	normal_style.border_width_top = 4
	normal_style.border_width_left = 4
	normal_style.border_width_right = 4
	normal_style.set_corner_radius_all(10)
	normal_style.content_margin_top = 10
	normal_style.content_margin_bottom = 10
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(0.25, 0.15, 0.15, 0.95)
	
	# Create Restart button
	var btn_restart = Button.new()
	btn_restart.text = "Restart"
	btn_restart.add_theme_font_size_override("font_size", 36)
	btn_restart.add_theme_stylebox_override("normal", normal_style)
	btn_restart.add_theme_stylebox_override("hover", hover_style)
	btn_restart.add_theme_stylebox_override("pressed", normal_style)
	vbox.add_child(btn_restart)
	
	# Create Main Menu button
	var btn_menu = Button.new()
	btn_menu.text = "Main Menu"
	btn_menu.add_theme_font_size_override("font_size", 36)
	btn_menu.add_theme_stylebox_override("normal", normal_style)
	btn_menu.add_theme_stylebox_override("hover", hover_style)
	btn_menu.add_theme_stylebox_override("pressed", normal_style)
	vbox.add_child(btn_menu)
	
	# Handle button clicks
	btn_restart.pressed.connect(func():
		Global.is_initialized = false # Reset inventory and upgrades
		get_tree().change_scene_to_file("res://scenes/world/world.tscn")
	)
	
	btn_menu.pressed.connect(func():
		Global.is_initialized = false
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	
	# Cinematic Sequence using Tweens
	var tween = create_tween()
	# 1. Fade to black background and fade in "YOU DIED."
	tween.tween_property(bg, "color:a", 1.0, 2.0)
	tween.parallel().tween_property(label, "modulate:a", 1.0, 1.0)
	
	# 2. Wait 2 seconds
	tween.tween_interval(2.0)
	
	# 3. Fade out "YOU DIED." text
	tween.tween_property(label, "modulate:a", 0.0, 1.5)
	
	# 4. Wait half a second, then fade in buttons
	tween.tween_interval(0.5)
	tween.tween_property(center, "modulate:a", 1.0, 1.5)

func shake_screen(intensity: float = 10.0, duration: float = 0.2) -> void:
	var cam = get_node_or_null("Camera2D")
	if not cam:
		return
		
	var original_offset = cam.offset
	var timer = get_tree().create_timer(duration)
	
	while timer.time_left > 0:
		cam.offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		await get_tree().process_frame
		
	cam.offset = original_offset

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("teleport"):
		global_position = spawn_position
		velocity = Vector2.ZERO
	elif event.is_action_pressed("place"):
		var world = get_parent()
		if world and world.has_method("place_block"):
			var blocks_node: TileMapLayer = world.get_node_or_null("Blocks")
			if blocks_node:
				var tile: Vector2i = blocks_node.local_to_map(blocks_node.to_local(get_global_mouse_position()))
				var player_tile: Vector2i = blocks_node.local_to_map(blocks_node.to_local(global_position))
				# Prevent placing on the player's body (feet or head)
				if tile == player_tile or tile == (player_tile + Vector2i(0, -1)):
					return
					
				if Vector2(tile).distance_to(Vector2(player_tile)) <= mine_reach:
					world.place_block(get_global_mouse_position())
	elif event is InputEventKey and event.keycode == KEY_Q and event.pressed and not event.echo:
		throw_pickaxe()

var active_boomerang: Node2D = null

func throw_pickaxe() -> void:
	if is_instance_valid(active_boomerang):
		return # Cannot throw again until the pickaxe returns
		
	var world = get_parent()
	var scene_path = "res://assets/sprites/weapon/stone pickaxe.tscn" # Default
	
	# Determine which pickaxe the player has equipped
	if world and "inventory_material" in world:
		var pickaxe_tex = world.inventory_material.get("pickaxe")
		if pickaxe_tex and pickaxe_tex.resource_path:
			if "diamond" in pickaxe_tex.resource_path.to_lower():
				scene_path = "res://assets/sprites/weapon/diamond pickaxe.tscn"
			elif "iron" in pickaxe_tex.resource_path.to_lower():
				scene_path = "res://assets/sprites/weapon/iron pickaxe.tscn"
				
	# Load the correct custom weapon scene
	var weapon_scene = load(scene_path)
	if not weapon_scene:
		return
	var boomerang = weapon_scene.instantiate()
	active_boomerang = boomerang
	
	# Attach the new boomerang script
	var script = load("res://scripts/Player/boomerang.gd")
	boomerang.set_script(script)
	
	# Add it to the world (parent of player)
	if world:
		world.add_child(boomerang)
		
		# Calculate throw target (e.g. 300 pixels towards mouse)
		var throw_dir = global_position.direction_to(get_global_mouse_position())
		var target_pos = global_position + throw_dir * 300.0
		
		# Initialize the boomerang (using call for dynamic script safety)
		boomerang.call("throw", self, target_pos)

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
	var direction: float = Input.get_axis("left", "right")
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
	var blocks_node: TileMapLayer = world.get_node_or_null("Blocks")
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


var has_tried_mining_stone: bool = false

func handle_mining(delta: float) -> void:
	var world: Node = get_parent()
	if not world or not world.has_method("is_mineable"):
		return

	# Check if they just tried to mine stone
	if Input.is_action_just_pressed("mine") and not has_tried_mining_stone:
		var blocks = world.get_node_or_null("Blocks")
		if blocks:
			var mouse_world = get_global_mouse_position()
			var p_tile = blocks.local_to_map(blocks.to_local(global_position))
			var click_tile = blocks.local_to_map(blocks.to_local(mouse_world))
			if Vector2(click_tile).distance_to(Vector2(p_tile)) <= mine_reach:
				if blocks.get_cell_source_id(click_tile) == 3: # STONE
					show_stone_warning()

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
		progress_bar.frame = int((_mine_timer / mine_time) * 4.0)

	if _mine_timer >= mine_time:
		_mine_timer = 0.0
		_current_mine_tile = Vector2i(-9999, -9999)
		if progress_bar:
			progress_bar.visible = false
		world.mine_tile(_target_tile, _mine_direction)

func show_stone_warning() -> void:
	has_tried_mining_stone = true
	var lbl = Label.new()
	lbl.text = "Stone is not breakable!"
	lbl.add_theme_color_override("font_color", Color(1, 0.4, 0.4, 1))
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.position = Vector2(-70, -60)
	lbl.z_index = 100
	add_child(lbl)
	
	var tween = create_tween()
	tween.tween_property(lbl, "position:y", -90.0, 3.0)
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, 3.0)
	tween.tween_callback(lbl.queue_free)


func update_animation() -> void:
	if not is_on_floor():
		if velocity.y < 0:
			play_animation("Jump")
		else:
			play_animation("falling")
	else:
		if abs(velocity.x) > 10.0:
			if velocity.x < 0:
				play_animation("left")
			else:
				play_animation("right")
		else:
			play_animation("idle")


func play_animation(animation_name: String) -> void:
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)
