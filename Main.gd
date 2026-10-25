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
@onready var time_label: Label = $HUD/LevelComplete/TimeLabel
@onready var win_sound: AudioStreamPlayer2D = get_node_or_null("WinSound")
@onready var select_sound: AudioStreamPlayer2D = get_node_or_null("SelectSound")

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	level_complete.hide()
	goal_zone.reached.connect(_on_goal_reached)
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
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
	_respawn.call_deferred()

func _respawn() -> void:
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
	# If this is Level 3 (the final level), lock the timer to record the final run time!
	if win_sound:
		win_sound.play()

	if _next_level() == "":
		GlobalTimer.stop_timer()
	
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	
	# --- FIXED: DYNAMIC LEVEL TITLE UPDATE ---
	var current_title: Label = get_node_or_null("HUD/LevelComplete/TitleLabel")
	if current_title:
		if _next_level() == "":
			current_title.text = "game complete!"
		elif get_scene_file_path().ends_with("level_1.tscn"):
			current_title.text = "level 1 complete"
		elif get_scene_file_path().ends_with("level_2.tscn"):
			current_title.text = "level 2 complete"

	# Grab the cumulative run hours from our background engine singleton
		# --- FIXED TIME DISPLAY SCANNING ---
	# Try to find the node even if its scene path changed slightly
	var final_clock_display: Label = get_node_or_null("HUD/LevelComplete/TimeLabel")
	
	if final_clock_display:
		final_clock_display.text = "TOTAL TIME: " + GlobalTimer.get_formatted_time()
	else:
		print("ERROR: TimeLabel node could not be found anywhere inside HUD/LevelComplete!")
		
	level_complete.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)



func _on_retry_pressed() -> void:
	if select_sound:
		select_sound.play()
	get_tree().reload_current_scene()

func _next_level() -> String:
	if get_scene_file_path().ends_with("level_1.tscn"):
		return "res://level_2.tscn"
	elif get_scene_file_path().ends_with("level_2.tscn"):
		return "res://level_3.tscn"
	elif get_scene_file_path().ends_with("level_3.tscn"):
		return ""
	return next_level_path

func _on_menu_pressed() -> void:
	if select_sound:
		select_sound.play()
		
	var next_level := _next_level()
	if next_level != "":
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		get_tree().change_scene_to_file(next_level)
	else:
		GlobalTimer.stop_timer()
		get_tree().change_scene_to_file("res://title_screen.tscn")
