extends Button

export var allyColour:Color
export var enemyColour:Color

signal selected(username)

func setup(username:String, kills:int=0, deaths:int=0, dots:int=0, ally:bool=true):
	$HBoxContainer/Username.text = username
	$HBoxContainer/Stats.text = "%s %s %s" % [kills, deaths, dots]
	theme.set_color("font_color", "Label", allyColour if ally else enemyColour)
	pass


func _on_PlayerEntry_pressed() -> void:
	emit_signal("selected", $HBoxContainer/Username.text)
