extends AnimatableBody2D

var held_player: CharacterBody2D = null

func _physics_process(delta: float) -> void:
	
	var target_pos = get_global_mouse_position()
	global_position = target_pos - Vector2(220, 0)

	# Handle Grabbing / Dragging
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if not held_player:
			var player = $"../player"
			
			if player and get_node("CollisionShape2D").shape.collide(
				get_node("CollisionShape2D").global_transform,
				player.get_node("CollisionShape2D").shape,
				player.get_node("CollisionShape2D").global_transform
			):
				held_player = player
				held_player.set_physics_process(false) # Freeze player gravity
	else:
		if held_player:
			held_player.velocity = Vector2.ZERO
			held_player.set_physics_process(true)
			held_player = null
	if held_player:
		held_player.global_position = get_global_mouse_position()
