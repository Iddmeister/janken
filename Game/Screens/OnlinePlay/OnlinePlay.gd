extends Control

onready var connectionStatus: Label = $Connecting/CenterContainer/VBoxContainer/ConnectionStatus

func _ready() -> void:
	Network.connect("connection_established", self, "connectionSucceeded")
	Network.connect("connection_failed", self, "connectionFailed")

func connectToServer():
	$Connecting.show()
	connectionStatus.text = "Connecting to Server..."
	$Connecting/CenterContainer/VBoxContainer/Retry.hide()
	$Connecting/CenterContainer/VBoxContainer/Back.hide()
	Network.connectToServer()
	
func connectionSucceeded():
	$Connecting.hide()
	
func connectionFailed():
	connectionStatus.text = "Failed to Connect to Server"
	$Connecting/CenterContainer/VBoxContainer/Retry.show()
	$Connecting/CenterContainer/VBoxContainer/Back.show()

func retryConnection() -> void:
	connectToServer()


func returnToMenu() -> void:
	hide()
