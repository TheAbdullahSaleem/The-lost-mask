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
	var t = clamp((current_y - start_y) / (end_y - start_y), 0.0, 1.0)
	
	var total_frames = hframes * vframes
	self.frame = int(t * (total_frames - 1))
