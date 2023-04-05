extends Node2D

var graphics:Dictionary = {
	0:preload("res://Player/Rock.tscn"),
	1:preload("res://Player/Paper.tscn"),
	2:preload("res://Player/Scissors.tscn")
}

var speed:float = 200
export var enemyColour:Color
export var allyColour:Color
export var selfColour:Color

var exiting:bool = false
var exitAngle:float

signal finished()

var path:PoolVector2Array

func setType(type:int):
	$Graphics.add_child(graphics[type].instance())

func _physics_process(delta: float) -> void:
	
	if exiting:
		$Graphics.global_rotation = lerp_angle($Graphics.global_rotation, exitAngle, 0.3*delta*60)
	
	if path.empty():
		return
	
	if (path[0]-position).length() <= speed*delta:
		var remainingDist:float = (speed*delta)-(path[0]-position).length()
		position = path[0]
		path.remove(0)
		if path.empty():
			emit_signal("finished")
		else:
			position += (path[0]-position).normalized()*remainingDist
	else:
		position += (path[0]-position).normalized()*speed*delta
		$Graphics.global_rotation = lerp_angle($Graphics.global_rotation, (path[0]-position).angle(), 0.3*delta*60)
