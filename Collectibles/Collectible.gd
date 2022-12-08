extends Area2D

class_name Collectible

signal collected()

export var points:int = 0

func collected(player:Player):
	emit_signal("collected")
	queue_free()
	pass

func _on_Collectible_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player"):
		collected(area)
