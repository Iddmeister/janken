extends Panel

signal back()
signal retry()

func failed():
	$CenterContainer/VBoxContainer/ConnectionStatus.text = "Failed to Connect to Server"
	$CenterContainer/VBoxContainer/Retry.show()
	$CenterContainer/VBoxContainer/Back.show()
	pass

func _on_Back_pressed() -> void:
	emit_signal("back")
	hide()

func _on_Retry_pressed() -> void:
	emit_signal("retry")
	Network.connectToServer()
	$CenterContainer/VBoxContainer/ConnectionStatus.text = "Connecting to Server..."
	$CenterContainer/VBoxContainer/Retry.hide()
	$CenterContainer/VBoxContainer/Back.hide()
