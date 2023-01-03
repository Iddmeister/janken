extends Node

func _ready() -> void:
	if Network.isServer:
		return
	Network.connect("connection_established", self, "connectedToServer")
	Network.connect("connection_failed", self, "connectionFailed")

func connectedToServer():
	$Loading.hide()
	$Login.show()
	
func connectionFailed():
	$Loading.failed()
	
func connectionClosed():
	$OnlinePlay.hide()
	$Login.hide()
	$Loading.failed()
	$Loading.show()
	

func _on_Menu_playOnline() -> void:
	Network.connectToServer()
	$Loading.show()

func _on_Login_loggedIn(username) -> void:
	$Login.hide()
	$OnlinePlay.loggedIn(username)
	$OnlinePlay.show()


func _on_OnlinePlay_logout() -> void:
	Network.sendData({"type":"logout"})
	$OnlinePlay.hide()
	$Login.show()


func _on_OnlinePlay_gameCreated(address, port) -> void:
	pass # Replace with function body.
