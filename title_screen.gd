extends Control

@onready var start_button: Button = $StartButton
@onready var quit_button: Button = $QuitButton

func _ready() -> void:
	# Make sure the mouse cursor is visible on the menu!
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Connect the buttons to our handlers below.
	start_button.pressed.connect(_on_start_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)

	# So pressing Enter / Space on the keyboard also starts the game.
	start_button.grab_focus()

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://level_1.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
