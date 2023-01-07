extends VBoxContainer

signal changedType(type)

var currentType:int = 0
var ready:bool = false

func setup(username:String, _ready, type:int, isMe:bool=true):
	$Name.text = username
	changeReady(_ready)
	changeType(type)
	$ChangeType.visible = isMe
	
func changeReady(_ready:bool=true):
	ready = _ready
	$Ready.modulate.a = 1 if ready else 0
	
func changeType(type:int):
	currentType = type
	for t in range(0, 3):
		$Type/Icon.get_node(String(t)).visible = t == currentType

func _on_ChangeType_pressed() -> void:
	var newType = currentType+1 if currentType <= 1 else 0
	emit_signal("changedType", newType)
