extends Node

func _ready() -> void:
	if Network.isServer:
		return
	Network.connect("connection_established", self, "connectedToServer")
	Network.connect("connection_failed", self, "connectionFailed")
	Network.connect("connection_lost", self, "connectionLost")

func connectedToServer():
	$Screens/Loading.hide()
	$Screens/Login.show()
	
	if Data.getData("lastUser") and Data.getData("lastPass"):
		$Screens/Login.autoLogin(Data.getData("lastUser"), Data.getData("lastPass"))
	
func connectionFailed():
	$Screens/Loading.failed()
	
func connectionLost():
	$Screens/OnlinePlay.hide()
	$Screens/Login.hide()
	$Screens/Loading.failed()
	$Screens/Loading.show()
	

func _on_Menu_playOnline() -> void:
	Network.connectToServer()
	$Screens/Loading.show()

func _on_Login_loggedIn(username) -> void:
	$Screens/Login.hide()
	$Screens/OnlinePlay.loggedIn(username)
	$Game.me = username
	$Screens/OnlinePlay.show()


func _on_OnlinePlay_logout() -> void:
	Network.sendData({"type":"logout"})
	$Screens/OnlinePlay.hide()
	$Screens/Login.show()


func _on_OnlinePlay_gameCreated(address, port, key) -> void:
	$Screens.hide()
	$Game.privateKey = key
	$Game.joinServer(address, port)


func _on_Game_gameEnded() -> void:
	$Screens/EndScreen.show()
	$Screens.show()


func _on_EndScreen_returnToLobby() -> void:
	$Screens/EndScreen.hide()


func _on_Login_cancelled() -> void:
	$Screens/Login.hide()
	Network.disconnectFromServer()
	
