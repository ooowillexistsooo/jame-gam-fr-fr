extends Area2D

## Emitted when the player reaches this goal zone.
signal reached

func _ready() -> void:
	# Listen for when a physics body enters this sensor zone
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Check if the thing that touched the goal is our little player guy
	if body.name == "player":
		reached.emit()
