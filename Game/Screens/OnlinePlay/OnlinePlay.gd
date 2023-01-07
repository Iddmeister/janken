extends Control

onready var userBox: PanelContainer = $User

signal gameCreated(address, port, key)
signal logout()

func _ready() -> void:
	Network.connect("data_recieved", self, "dataRecieved")
	
func dataRecieved(data:Dictionary):
	
	match data.type:
		"gameCreated":
			emit_signal("gameCreated", data.address, data.port, data.key)

func loggedIn(username):
	userBox.get_node("MarginContainer/VBoxContainer/Username").text = username
	$Navigation/Lobby.myUsername = username

func returnToMenu() -> void:
	hide()

func _on_Logout_pressed() -> void:
	emit_signal("logout")

