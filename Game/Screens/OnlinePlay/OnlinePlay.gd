extends Control

onready var connectionStatus: Label = $Connecting/CenterContainer/VBoxContainer/ConnectionStatus
onready var joinQueue: Button = $VBoxContainer/Options/MarginContainer/JoinQueue
onready var queueStatus: Label = $VBoxContainer/Options/MarginContainer/JoinQueue/HBoxContainer/Status
onready var numPlayersOnline: Label = $VBoxContainer/Options/MarginContainer/JoinQueue/HBoxContainer/NumPlayer/Number

signal joinedGame(key, address, port)

func _ready() -> void:
	if not Network.isServer:
		Network.connect("connection_established", self, "connectionSucceeded")
		Network.connect("connection_failed", self, "connectionFailed")
		Network.connect("data_recieved", self, "dataRecieved")

func connectToServer():
	$Connecting.show()
	connectionStatus.text = "Connecting to Server..."
	$Connecting/CenterContainer/VBoxContainer/Retry.hide()
	$Connecting/CenterContainer/VBoxContainer/Back.hide()
	Network.connectToServer()
	
func connectionSucceeded():
	$Connecting.hide()
	Network.sendData({"type":"playerConnect"})
	updateNetworkInfo()
	
func connectionFailed():
	connectionStatus.text = "Failed to Connect to Server"
	$Connecting/CenterContainer/VBoxContainer/Retry.show()
	$Connecting/CenterContainer/VBoxContainer/Back.show()
	
func dataRecieved(data:Dictionary):
	match data.type:
		"update":
			numPlayersOnline.text = String(max(int(data.get("playersOnline", numPlayersOnline.text))-1, 0))
		"gameFound":
			emit_signal("joinedGame", data.get("key", "a"), "127.0.0.1", 5072)
	

func retryConnection() -> void:
	connectToServer()


func returnToMenu() -> void:
	hide()



func _on_JoinQueue_toggled(button_pressed: bool) -> void:
	queueStatus.text = "SEARCH" if button_pressed else "PLAY"
	if button_pressed:
		Network.sendData({"type":"createTeam"})
		Network.sendData({"type":"changeType", "newType":0})
		Network.sendData({"type":"changeReady", "ready":true})


func _on_RequestUpdate_timeout() -> void:
	updateNetworkInfo()
		
func updateNetworkInfo():
	if Network.connected and not Network.isServer:
		Network.sendData({"type":"info", "info":["playersOnline"]})
