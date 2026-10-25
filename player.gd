extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const HAND_JUMP_VELOCITY = -550.0

# Tracks if a high horizontal velocity should override standard player control
var is_launched := false
# --- FIX: Track how long the launch grace period lasts ---
var launch_grace_timer := 0.0

# Safe node catching using @onready
@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

func _physics_process(delta: float) -> void:
	if not is_physics_processing():
		velocity = Vector2.ZERO
		return
	
	# Tick down the air launch grace period
	if launch_grace_timer > 0.0:
		launch_grace_timer -= delta
	
	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		# ONLY turn off the launch state if the player isn't moving upwards anymore!
		if velocity.y >= 0:
			is_launched = false

	# Jump with SPACEBAR, UP ARROW, or W
	var wants_to_jump = Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W)
	if wants_to_jump and is_on_floor():
		# Play our jump sound effect safely!
		var jump_audio = get_node_or_null("JumpSound")
		if jump_audio:
			jump_audio.play()

		if _is_standing_on_hand():
			velocity.y = HAND_JUMP_VELOCITY
		else:
			velocity.y = JUMP_VELOCITY

	var move_left = Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A)
	var move_right = Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)
	
	var direction = 0
	if move_left:
		direction -= 1
	if move_right:
		direction += 1

	# --- HORIZONTAL LAUNCH PROTECTION ---
	if is_launched:
		if direction != 0:
			velocity.x = direction * SPEED
			is_launched = false
			launch_grace_timer = 0.0 # Clear grace if player overrides manually
		else:
			pass
	else:
		if direction != 0:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	# --- BULLETPROOF ANIMATION EXECUTION ---
	if sprite and sprite.sprite_frames:
		if direction > 0 and sprite.sprite_frames.has_animation("run_right"):
			sprite.play("run_right")
		elif direction < 0 and sprite.sprite_frames.has_animation("run_left"):
			sprite.play("run_left")
		else:
			if is_launched and sprite.sprite_frames.has_animation("run_right"):
				sprite.play("run_right")
			elif sprite.sprite_frames.has_animation("idle"):
				sprite.play("idle")

	move_and_slide()

	# --- ATOMIC JUMP CAPPING ---
	if not is_on_floor() and velocity.y < -650.0 and not is_launched:
		velocity.y = -650.0

func _is_standing_on_hand() -> bool:
	# Ignore hand platform checking if we were just launched a split second ago!
	if launch_grace_timer > 0.0:
		return false
		
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider:
			if collider.name.to_lower() == "hand" or collider.is_in_group("hand"):
				return true
	return false
