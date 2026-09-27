extends Sprite2D
@export var player : CharacterBody2D
@export var target : Node2D
@export var min_detect_distance : float
@export var max_detect_distance : float
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not player or not target: return
	var current_distance = player.global_position.direction_to(target.global_position)
	var t = remap(current_distance,min_detect_distance,max_detect_distance,1.0,0.0)
	t = clamp(t,0.0,1.0)
	var total_frames = hframes * vframes
	self.frame = int(t*(total_frames-1))
