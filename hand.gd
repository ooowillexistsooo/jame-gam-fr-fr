class_name Hand
extends AnimatableBody2D

## Emitted every physics frame with the hand's current stamina.
signal stamina_changed(current: float, maximum: float)
## Emitted when the hand switches between tired and rested.
signal tired_changed(tired: bool)

const MAX_STAMINA := 5.0
const DRAIN_PER_SEC := 10.0    # about 25 seconds of helping (carrying OR being stood on)
const RECOVER_PER_SEC := 3  # about 16.7 seconds to fully rest
const FREEZE_COOLDOWN = 0.6    # seconds before a rested hand may move again after the player leaves it

var stamina: float = MAX_STAMINA
var is_tired: bool = false

var held_player: CharacterBody2D = null

# variables
var locked_hand_position: Vector2 = Vector2.ZERO
var time_since_riding: float = 0.0
var hand_is_frozen: bool = false
var was_frozen_last_frame: bool = false

@onready var grab_area: Area2D = $GrabArea
@onready var body_visual: ColorRect = $ColorRect

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
		time_since_riding = 0.0 # player is present, keep the timer reset
		if not hand_is_frozen:
			# Snap and record our coordinates the exact frame they land
			locked_hand_position = global_position
			hand_is_frozen = true
	else:
		time_since_riding += delta
		# Unfreeze once the timer runs out (and not holding left-click), or if exhausted.
		if hand_is_frozen and (is_tired or (time_since_riding >= FREEZE_COOLDOWN and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))):
			hand_is_frozen = false

	if hand_is_frozen:
		# Lock the hand firmly to its snapshot coordinate
		global_position = locked_hand_position
	else:
		# teleport the computer mouse back to the hand before tracking movement!
		if was_frozen_last_frame:
			var screen_pixel_position = get_global_transform_with_canvas().origin
			get_viewport().warp_mouse(screen_pixel_position) # 0,0 offset works perfectly!
			global_position = locked_hand_position
		else:
			global_position = get_global_mouse_position()

	# remembers where the hand was whilst frozen
	was_frozen_last_frame = hand_is_frozen

	# --- Picking up / dropping ---
	if held_player and is_tired:
		# Too exhausted to keep holding him.
		_release_player()
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if not held_player and not is_tired:
			if player and grab_area.overlaps_body(player):
				held_player = player
				held_player.set_physics_process(false)
	else:
		if held_player:
			_release_player()

	# hold player still whilst pinching
	if held_player:
		held_player.global_position = grab_area.global_position

func _release_player() -> void:
	if held_player:
		held_player.velocity = Vector2.ZERO
		held_player.set_physics_process(true)
		held_player = null

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
	# An exhausted hand goes limp: it can no longer be stood on, and its colour dulls.
	for child in get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", tired)
	if body_visual:
		body_visual.modulate = Color(1.0, 0.7, 0.7, 0.5) if tired else Color(1, 1, 1, 1)

func get_stamina_ratio() -> float:
	return stamina / MAX_STAMINA
