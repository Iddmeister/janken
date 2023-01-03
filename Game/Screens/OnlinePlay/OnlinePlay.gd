extends Control

onready var userBox: PanelContainer = $User

signal gameCreated(address, port)
signal logout()

func _ready() -> void:
	Network.connect("data_recieved", self, "dataRecieved")
	
func dataRecieved(data:Dictionary):
	
	match data.type:
		"gameCreated":
			emit_signal("gameCreated", data.address, data.port)
	

func loggedIn(username):
	userBox.get_node("MarginContainer/VBoxContainer/Username").text = username

func returnToMenu() -> void:
	hide()

func _on_Logout_pressed() -> void:
	emit_signal("logout")

