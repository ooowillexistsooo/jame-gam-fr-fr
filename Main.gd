extends Node2D

## Where the player respawns after dying (set per level in the scene).
@export var spawn_point: Vector2 = Vector2(43, 63)
## If set, the win screen's menu button loads this scene (i.e. the next level).
@export var next_level_path: String = ""

const STAMINA_INSET := 3.0
const STAMINA_FULL_WIDTH := 217.0
const STAMINA_LOW_COLOR := Color(1.0, 0.3, 0.25)
const STAMINA_HIGH_COLOR := Color(0.35, 0.85, 0.45)

@onready var goal_zone: Area2D = $GoalZone
@onready var player: CharacterBody2D = $player
@onready var hand: Node = $hand
@onready var level_complete: Control = $HUD/LevelComplete
@onready var retry_button: Button = $HUD/LevelComplete/RetryButton
@onready var menu_button: Button = $HUD/LevelComplete/MenuButton
@onready var stamina_fill: ColorRect = $HUD/StaminaBar/Fill
@onready var stamina_label: Label = $HUD/StaminaBar/Label
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	# The hand is driven by the mouse, so keep the OS cursor hidden.
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	level_complete.hide()
	goal_zone.reached.connect(_on_goal_reached)
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.text = "NEXT LEVEL" if _next_level() != "" else "MENU"
	menu_button.pressed.connect(_on_menu_pressed)
	hand.connect("stamina_changed", _on_stamina_changed)
	hand.connect("tired_changed", _on_hand_tired_changed)
	for hazard in get_tree().get_nodes_in_group("death_zone"):
		hazard.connect("player_died", _on_player_died)

func _on_stamina_changed(current: float, maximum: float) -> void:
	var ratio: float = clampf(current / maximum, 0.0, 1.0)
	stamina_fill.offset_right = STAMINA_INSET + (STAMINA_FULL_WIDTH - STAMINA_INSET) * ratio
	stamina_fill.color = STAMINA_LOW_COLOR.lerp(STAMINA_HIGH_COLOR, ratio)

func _on_hand_tired_changed(tired: bool) -> void:
	stamina_label.text = "HAND: TIRED" if tired else "HAND"
	stamina_label.modulate = Color(1.0, 0.6, 0.6) if tired else Color(1, 1, 1)

func _on_player_died() -> void:
	# Deferred so we don't mutate physics state during the collision callback.
	_respawn.call_deferred()

func _respawn() -> void:
	# Return the little guy to the level start and reset the hand + any moving platforms.
	if hand.has_method("reset"):
		hand.call("reset")
	player.global_position = spawn_point
	player.velocity = Vector2.ZERO
	player.set_physics_process(true)
	for platform in get_tree().get_nodes_in_group("moving_platform"):
		if platform.has_method("reset"):
			platform.call("reset")
	if camera.has_method("snap_to_player"):
		camera.call("snap_to_player")

func _on_goal_reached() -> void:
	# Freeze the little guy and show the placeholder win screen.
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	level_complete.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	retry_button.grab_focus()

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()

func _next_level() -> String:
	# Level 1 leads into level 2; anything else uses next_level_path (or none).
	if get_scene_file_path().ends_with("level_1.tscn"):
		return "res://level_2.tscn"
	return next_level_path

func _on_menu_pressed() -> void:
	var next_level := _next_level()
	if next_level != "":
		get_tree().change_scene_to_file(next_level)
	else:
		get_tree().change_scene_to_file("res://title_screen.tscn")

	
