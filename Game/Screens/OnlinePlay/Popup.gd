extends Button

onready var statsControl: Control = $PanelContainer/Control/PlayerStats

func _ready() -> void:
	Network.connect("data_recieved", self, "dataRecieved")
	
func dataRecieved(data:Dictionary):
	
	match data.type:
		
		"playerStats":
			statsControl.setStats(data.stats)
		"battleLog":
			for battle in data.battles:
				$"%BattleLog".addBattle(battle)

func requestPlayerStats(username:String):
	Network.sendData({"type":"playerStats", "username":username})
	$"%BattleLog".hide()
	show()
	statsControl.setUsername(username)
	statsControl.show()
	statsControl.loading()
	pass
	
func requestBattleLog(username:String):
	Network.sendData({"type":"battleLog", "username":username})
	show()
	statsControl.hide()
	$"%BattleLog".show()

func _on_Back_pressed() -> void:
	hide()

func _on_InfoPopup_button_down() -> void:
	hide()
