extends Area2D

class_name Collectible

var isCollected:bool = false

signal collected(team, points)

export var points:int = 0

puppetsync func collected(team:int):
	isCollected = true
	emit_signal("collected", team, points)
	destroy()
	
func destroy():
	queue_free()

func _on_Collectible_area_entered(area: Area2D) -> void:
	if isCollected:
		return
	if is_network_master():
		if area.is_in_group("Player"):
			rpc("collected", area.team)
