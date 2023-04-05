extends Control

onready var userBox: PanelContainer = $User
onready var infoPopup: Button = $InfoPopup

signal gameCreated(address, port, key)
signal logout()

var myUsername:String

func _ready() -> void:
	Network.connect("data_recieved", self, "dataRecieved")
	
func dataRecieved(data:Dictionary):
	
	match data.type:
		"gameCreated":
			emit_signal("gameCreated", data.address, data.port, data.key)
			$"%Ready".pressed = false
			$"%Ready".text = "READY"
		"playerCount":
			$"%PlayerCount".text = "%s Online" % data.count

func loggedIn(username):
	userBox.get_node("MarginContainer/VBoxContainer/Username").text = username
	$Navigation/Lobby.myUsername = username
	myUsername = username
	$"%BattleLog".username = myUsername
	

func returnToMenu() -> void:
	hide()

func _on_Logout_pressed() -> void:
	$Navigation/Lobby.leaveTeam()
	$"%BattleLog".clearBattles()
	$"%PlayerStats".clearStats()
	emit_signal("logout")


func _on_UpdateInfo_timeout() -> void:
	if Network.connected:
		Network.sendData({"type":"playerCount"})

func _on_Stats_pressed() -> void:
	infoPopup.requestPlayerStats(myUsername)

func _on_BattleLog_pressed() -> void:
	infoPopup.requestBattleLog(myUsername)
