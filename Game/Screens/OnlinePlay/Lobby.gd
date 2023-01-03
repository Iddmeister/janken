extends Panel

func joinedTeam(code:String, players:Dictionary):
	$TeamCode/Panel/VBoxContainer/HBoxContainer/Code.text = code
	pass

func _on_Ready_toggled(button_pressed: bool) -> void:
	Network.sendData({"type":"changeReady", "ready":button_pressed})


func _on_Copy_pressed() -> void:
	OS.set_clipboard($TeamCode/Panel/VBoxContainer/HBoxContainer/Code.text)


func _on_LeaveTeam_pressed() -> void:
	Network.sendData({"type":"leaveTeam"})
	hide()
