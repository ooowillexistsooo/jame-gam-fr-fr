extends Camera2D

const SCREEN_WIDTH = 2304.0
const CAMERA_SPEED = 6500.0 
@onready var player = $"../player"

var last_screen_index = 0
var is_transitioning = false

func _ready() -> void:
	enabled = true 
	
	zoom = Vector2(0.5, 0.5) 
	
	if player:
		last_screen_index = floor(player.global_position.x / SCREEN_WIDTH)
		global_position.x = (last_screen_index * SCREEN_WIDTH) + (SCREEN_WIDTH / 2.0)
		
		
		global_position.y = -70.0 
	else:
		print("WARNING: Camera cannot find the player node!")

func _process(delta: float) -> void:
	if not player:
		return

	var current_screen_index = floor(player.global_position.x / SCREEN_WIDTH)

	if current_screen_index != last_screen_index and not is_transitioning:
		is_transitioning = true
		player.set_physics_process(false)
		player.velocity = Vector2.ZERO 
		
		if current_screen_index > last_screen_index:
			player.global_position.x += 32 
		elif current_screen_index < last_screen_index:
			player.global_position.x -= 32
			
		last_screen_index = current_screen_index

	var target_x = (current_screen_index * SCREEN_WIDTH) + (SCREEN_WIDTH / 2.0)

	if is_transitioning:
		global_position.x = move_toward(global_position.x, target_x, CAMERA_SPEED * delta)
		
		if abs(global_position.x - target_x) < 5.0:
			global_position.x = target_x 
			is_transitioning = false
			player.set_physics_process(true)
