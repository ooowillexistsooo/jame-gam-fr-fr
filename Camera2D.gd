extends Camera2D

# Celeste-style room camera: the world is a grid of rooms and the camera snaps
# to whichever room the player is in (both horizontally AND vertically).
const ROOM_W := 2304.0
const ROOM_H := 1296.0
const ORIGIN_Y := -718.0   # top edge of room row 0 (the old fixed band)
const PAN_SPEED := 6500.0

@onready var player = $"../player"

var last_col := 0
var last_row := 0
var is_transitioning := false
var _target := Vector2.ZERO

func _ready() -> void:
	enabled = true
	zoom = Vector2(0.5, 0.5)
	if player:
		_set_room_from_player()
		global_position = _target
	else:
		print("WARNING: Camera cannot find the player node!")

func _room_of(pos: Vector2) -> Vector2i:
	return Vector2i(int(floor(pos.x / ROOM_W)), int(floor((pos.y - ORIGIN_Y) / ROOM_H)))

func _room_center(col: int, row: int) -> Vector2:
	return Vector2(col * ROOM_W + ROOM_W / 2.0, row * ROOM_H + ORIGIN_Y + ROOM_H / 2.0)

func _set_room_from_player() -> void:
	var room := _room_of(player.global_position)
	last_col = room.x
	last_row = room.y
	_target = _room_center(room.x, room.y)

func _process(delta: float) -> void:
	if not player:
		return
	var room := _room_of(player.global_position)
	if not is_transitioning and (room.x != last_col or room.y != last_row):
		last_col = room.x
		last_row = room.y
		_target = _room_center(room.x, room.y)
		is_transitioning = true
	if is_transitioning:
		global_position = global_position.move_toward(_target, PAN_SPEED * delta)
		if global_position.distance_to(_target) < 2.0:
			global_position = _target
			is_transitioning = false

func snap_to_player() -> void:
	# Instantly centre on the player's room (used on respawn) - no pan.
	if not player:
		return
	_set_room_from_player()
	is_transitioning = false
	global_position = _target
