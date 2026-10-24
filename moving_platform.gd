class_name MovingPlatform
extends AnimatableBody2D

## Ping-pongs smoothly between this node's start position and start + move_offset.
## Being an AnimatableBody2D, a CharacterBody2D standing on it is carried along
## automatically (Godot's platform_floor_layers defaults to following all floors).

@export var move_offset: Vector2 = Vector2(400.0, 0.0)
@export_range(0.1, 20.0, 0.1) var duration: float = 3.0  # seconds for one leg

var _start_position: Vector2 = Vector2.ZERO
var _elapsed: float = 0.0

func _ready() -> void:
	_start_position = global_position

func _physics_process(delta: float) -> void:
	_elapsed += delta
	var cycle: float = duration * 2.0
	var t: float = fmod(_elapsed, cycle) / duration  # 0 .. 2
	var f: float = t if t <= 1.0 else 2.0 - t          # triangle wave 0 .. 1 .. 0
	f = f * f * (3.0 - 2.0 * f)                        # smooth ease in/out
	global_position = _start_position + move_offset * f

func reset() -> void:
	_elapsed = 0.0
	global_position = _start_position