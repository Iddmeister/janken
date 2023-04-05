extends Object

class_name Bot

var player
var changeTime:float = 0.5
var directions = [Vector2(-1, 0), Vector2(1, 0), Vector2(0, 1), Vector2(0, -1)]

func _init(_player) -> void:
	player = _player

func update(delta:float):
	
	changeTime -= delta
	if changeTime <= 0:
		directions.shuffle()
		player.changeAimDirection(directions[0])
		changeTime = 0.5
