tool

extends Position2D

var graphics:Dictionary = {
	0:preload("res://Player/Rock.tscn"),
	1:preload("res://Player/Paper.tscn"),
	2:preload("res://Player/Scissors.tscn")
}

export(int, "Rock", "Paper", "Scissors") var type:int setget setType
export(int, "Team 1", "Team 2") var team:int
export var startDirection:Vector2 = Vector2(-1, 0)

func setType(val):
	type = val
	if is_inside_tree() and Engine.is_editor_hint():
		
		if get_child_count() > 0:
			get_child(0).free()
		
		add_child(graphics[type].instance())
		
func _ready() -> void:
	if Engine.is_editor_hint():
		if get_child_count() > 0:
			get_child(0).free()
		add_child(graphics[type].instance())
