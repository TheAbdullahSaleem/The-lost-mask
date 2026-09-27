extends Sprite2D

@export var min_detect_distance : float = 50.0
@export var max_detect_distance : float = 2000.0

var player: Node2D
var target: Node2D

func _process(delta: float) -> void:
	# Dynamically find player
	if not is_instance_valid(player):
		var root = get_tree().current_scene
		if root:
			player = root.get_node_or_null("Player")
			
	if not player: 
		return
		
	# The player starts near y = 48.
	# Door 1 is at y = 1795.
	# Door 2 is at y = 3987.
	# We map the player's Y position directly to the progress bar frames!
	var start_y = 48.0
	var end_y = 3987.0
	
	var current_y = player.global_position.y
	
	# Piecewise mapping to match the hand-drawn UI frames:
	# Surface (y=48) -> Frame 0
	# Door 1 (y=1795) -> Frame 6 (Where the yellow icon is drawn)
	# Door 2 (y=3987) -> Frame 17 (Where the red X is drawn)
	
	var frame_calc = 0.0
	
	if current_y <= 1795.0:
		var t = clamp((current_y - 48.0) / (1795.0 - 48.0), 0.0, 1.0)
		frame_calc = lerp(0.0, 6.0, t)
	elif current_y <= 3987.0:
		var t = clamp((current_y - 1795.0) / (3987.0 - 1795.0), 0.0, 1.0)
		frame_calc = lerp(6.0, 17.0, t)
	else:
		var t = clamp((current_y - 3987.0) / 1000.0, 0.0, 1.0) # past door 2
		frame_calc = lerp(17.0, 19.0, t)
		
	var total_frames = hframes * vframes
	self.frame = clamp(int(frame_calc), 0, total_frames - 1)
