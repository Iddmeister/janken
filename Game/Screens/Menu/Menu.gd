extends Control



func _on_PlayOnline_pressed() -> void:
	$OnlinePlay.show()
	$OnlinePlay.connectToServer()


func _on_Quit_pressed() -> void:
	get_tree().quit()
