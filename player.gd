extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

func _physics_process(delta: float) -> void:
	if not is_physics_processing():
		velocity = Vector2.ZERO
		return
	
	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump with SPACEBAR, UP ARROW, or W
	var wants_to_jump = Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W)
	if wants_to_jump and is_on_floor():
		velocity.y = JUMP_VELOCITY

	
	var move_left = Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A)
	var move_right = Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)
	
	var direction = 0
	if move_left:
		direction -= 1
	if move_right:
		direction += 1

	# Apply the movement
	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
