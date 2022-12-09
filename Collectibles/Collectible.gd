extends Area2D

class_name Collectible

signal collected(team, points)

export var points:int = 0

puppetsync func collected(team:int):
	emit_signal("collected", team, points)
	queue_free()

func _on_Collectible_area_entered(area: Area2D) -> void:
	if is_network_master():
		if area.is_in_group("Player"):
			rpc("collected", area.team)
