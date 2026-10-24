class_name DeathZone
extends Area2D

## A hazard floor / void. Emits player_died when the player touches it; the
## level controller (Main.gd) listens and respawns the player.

signal player_died

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "player":
		player_died.emit()