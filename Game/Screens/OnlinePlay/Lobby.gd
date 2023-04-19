extends Panel

var PlayerIcon = preload("res://Screens/OnlinePlay/PlayerIcon.tscn")

onready var playersContainer: HBoxContainer = $CenterContainer/Players
onready var queueStatus: HBoxContainer = $VBoxContainer/Status

var myUsername:String

func _ready() -> void:
	Network.connect("data_recieved", self, "dataRecieved")
	
func dataRecieved(data:Dictionary):
	
	match data.type:
		
		"playerLeft":
			removePlayer(data.player)
			queueStatus.get_node("Queue").hide()
			
		"playerJoined":
			addPlayer(data.player, data.ready, data.newType)
		
		"playerChangedType":
			if playersContainer.has_node(data.player):
				playersContainer.get_node(data.player).changeType(data.newType)
				
		"playerChangedReady":
			if playersContainer.has_node(data.player):
				playersContainer.get_node(data.player).changeReady(data.ready)
				
				for player in playersContainer.get_children():
					if not player.ready:
						queueStatus.get_node("Queue").hide()
						return
						
				queueStatus.get_node("Queue").show()
		
		"typeTakenError":
			$"%TypeTaken".show()
			$"%TypeTaken/Delay".start()
			$"%Ready".pressed = false

func addPlayer(username:String, ready:bool=false, type:int=0):
	var p = PlayerIcon.instance()
	p.name = username
	playersContainer.add_child(p)
	p.connect("changedType", self, "changeType")
	p.setup(username, ready, type, username == myUsername)
	
func changeType(type:int):
	Network.sendData({"type":"changeType", "newType":type})
	
func removePlayer(username:String):
	if playersContainer.has_node(username):
		playersContainer.get_node(username).queue_free()
	
func playerJoinedTeam(data:Dictionary):
	addPlayer(data.player, data.ready, data.type)
	
func joinedTeam(code:String):
	$TeamCode/Panel/VBoxContainer/HBoxContainer/Code.text = code

func _on_Ready_toggled(button_pressed: bool) -> void:
	$"%Ready".text = "CANCEL" if button_pressed else "READY"
	Network.sendData({"type":"changeReady", "ready":button_pressed})


func _on_Copy_pressed() -> void:
	OS.set_clipboard($TeamCode/Panel/VBoxContainer/HBoxContainer/Code.text)


func _on_LeaveTeam_pressed() -> void:
	leaveTeam()
	
func leaveTeam():
	for player in playersContainer.get_children():
		player.queue_free()
	queueStatus.get_node("Queue").hide()
	$"%Ready".pressed = false
	$"%Ready".text = "READY"
	Network.sendData({"type":"leaveTeam"})
	hide()
