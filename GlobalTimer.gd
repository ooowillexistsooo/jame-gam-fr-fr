extends Node

var total_time: float = 0.0
var is_active: bool = false

func _process(delta: float) -> void:
	if is_active:
		total_time += delta

func start_timer() -> void:
	total_time = 0.0
	is_active = true

func stop_timer() -> void:
	is_active = false

func get_formatted_time() -> String:
	var total_seconds_int := int(total_time)
	var minutes := total_seconds_int / 60
	var seconds := total_seconds_int % 60
	var hundredths := int((total_time - float(total_seconds_int)) * 100.0)
	return "%02d:%02d.%02d" % [minutes, seconds, hundredths]
