class_name Hand
extends AnimatableBody2D

## Emitted every physics frame with the hand's current stamina.
signal stamina_changed(current: float, maximum: float)
## Emitted when the hand switches between tired and rested.
signal tired_changed(tired: bool)

const MAX_STAMINA := 5.0
const DRAIN_PER_SEC := 8.0    # about 25 seconds of helping (carrying OR being stood on)
const RECOVER_PER_SEC := 2.5   # about 16.7 seconds to fully rest
const FREEZE_COOLDOWN = 0.7    # seconds before a rested hand may move again after the player leaves it

# --- LAUNCHER MECHANICS ---
const HOLD_DURATION := 0.05     # How long to hold him before launching (seconds)
const LAUNCH_VELOCITY_Y := -750.0 # Force of the upward launch (Negative is UP in Godot)
const LAUNCH_VELOCITY_X := 170.0  

var stamina: float = MAX_STAMINA
var is_tired: bool = false

var held_player: CharacterBody2D = null
var launch_timer: float = 0.0  # Tracks how long the player has been held

# variables
var locked_hand_position: Vector2 = Vector2.ZERO
var time_since_riding: float = 0.0
var hand_is_frozen: bool = false
var was_frozen_last_frame: bool = false

@onready var grab_area: Area2D = $GrabArea
@onready var hand_sprite: AnimatedSprite2D = $HandSprite

func _physics_process(delta: float) -> void:
	var player: CharacterBody2D = $"../player"

	# detect if the player is physically touching the hand surface right now
	var player_is_touching := false
	if player and player.is_on_floor():
		var collision := player.get_last_slide_collision()
		if collision and collision.get_collider() == self:
			player_is_touching = true

	# The hand is "helping" whenever it carries the player or serves as a platform.
	var is_helping := player_is_touching or held_player != null

	# --- Stamina: drain while helping, recover while resting ---
	if is_helping and not is_tired:
		stamina = maxf(stamina - DRAIN_PER_SEC * delta, 0.0)
	elif not is_helping:
		stamina = minf(stamina + RECOVER_PER_SEC * delta, MAX_STAMINA)

	var was_tired := is_tired
	if not is_tired and stamina <= 0.0:
		is_tired = true
	elif is_tired and stamina >= MAX_STAMINA:
		is_tired = false
	if is_tired != was_tired:
		_apply_tired_state(is_tired)
		tired_changed.emit(is_tired)
	stamina_changed.emit(stamina, MAX_STAMINA)

	# --- Freeze into a stable platform while the player stands on the hand ---
	if player_is_touching and not is_tired:
		time_since_riding = 0.0 
		if not hand_is_frozen:
			locked_hand_position = global_position
			hand_is_frozen = true
	else:
		time_since_riding += delta
		if hand_is_frozen and (is_tired or (time_since_riding >= FREEZE_COOLDOWN and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))):
			hand_is_frozen = false

	# --- PHYSICS-BASED MOUSE TRACKING ---
	if hand_is_frozen:
		global_position = locked_hand_position
	else:
		if was_frozen_last_frame:
			var screen_pixel_position = get_global_transform_with_canvas().origin
			get_viewport().warp_mouse(screen_pixel_position) 
			global_position = locked_hand_position
		else:
			var target_mouse_pos = get_global_mouse_position()
			
			# Calculate the travel path needed to reach the mouse coordinates this frame
			var velocity_to_mouse = target_mouse_pos - global_position
			
			# Sweeps the path frame-by-frame and stops cleanly at your red Layer 4 shapes!
			move_and_collide(velocity_to_mouse)

	was_frozen_last_frame = hand_is_frozen

	# --- Picking up / Slingshot launching ---
	if held_player:
		if is_tired:
			_release_player()
		else:
			launch_timer += delta
			if launch_timer >= HOLD_DURATION:
				_launch_player_upwards()
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if not held_player and not is_tired:
			if player and grab_area.overlaps_body(player):
				held_player = player
				held_player.set_physics_process(false)
				launch_timer = 0.0 

	# --- ANIMATION SWITCHER (Left-Click Driven) ---
	if not is_tired:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if hand_sprite and hand_sprite.animation != "pinch":
				hand_sprite.play("pinch")
		else:
			if hand_sprite and hand_sprite.animation != "idle" and held_player == null:
				hand_sprite.play("idle")

	if held_player:
		held_player.global_position = grab_area.global_position

func _launch_player_upwards() -> void:
	if held_player:
		# 1. Exhaust the hand and turn off its collision shapes completely
		stamina = 0.0
		is_tired = true
		_apply_tired_state(true) 
		tired_changed.emit(true)
		stamina_changed.emit(stamina, MAX_STAMINA)
		
		# 2. Inform the player object that they are in a high-velocity launch state
		if "is_launched" in held_player:
			held_player.is_launched = true
		# --- FIX: Inject the temporary collision grace period ---
		if "launch_grace_timer" in held_player:
			held_player.launch_grace_timer = 0.15
			
		# 3. Teleport the player slightly up and right out of the hand's box 
		held_player.global_position += Vector2(15, -15)
		
		# 4. Restore physics processing
		held_player.set_physics_process(true)
		
		# 5. Inject the launch velocity
		held_player.velocity.y = LAUNCH_VELOCITY_Y
		held_player.velocity.x = LAUNCH_VELOCITY_X
		held_player = null
		
		if hand_sprite and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			hand_sprite.play("idle")


func _release_player() -> void:
	if held_player:
		held_player.velocity = Vector2.ZERO
		held_player.set_physics_process(true)
		held_player = null
	launch_timer = 0.0
	
	if hand_sprite and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		hand_sprite.play("idle")


func reset() -> void:
	# Called when the player respawns: drop everything and return to full stamina.
	_release_player()
	stamina = MAX_STAMINA
	is_tired = false
	hand_is_frozen = false
	was_frozen_last_frame = false
	_apply_tired_state(false)
	stamina_changed.emit(stamina, MAX_STAMINA)
	tired_changed.emit(false)

func _apply_tired_state(tired: bool) -> void:
	# An exhausted hand goes limp: it can no longer be stood on, and its colour dulls or fades.
	for child in get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", tired)
			
	if hand_sprite:
		hand_sprite.modulate = Color(1.0, 0.7, 0.7, 0.5) if tired else Color(1, 1, 1, 1)
		# --- FIXED: Force the open/idle posture while resting ---
		if tired:
			hand_sprite.play("idle")

func get_stamina_ratio() -> float:
	return stamina / MAX_STAMINA
