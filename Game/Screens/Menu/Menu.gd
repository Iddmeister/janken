extends Control

signal playOnline()

func _on_PlayOnline_pressed() -> void:
	emit_signal("playOnline")

func _on_Quit_pressed() -> void:
	get_tree().quit()
