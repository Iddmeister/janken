extends Control

var PastBattle = preload("res://Screens/OnlinePlay/BattleLog/PastBattle.tscn")
var username:String

signal showMore()

func _ready() -> void:
	Network.connect("data_recieved", self, "dataRecieved")
	
func show():
	$Error.hide()
	.show()
	
func requestBattles(_username:String):
	if _username == username and $ScrollContainer/Battles.get_child_count() > 1:
		return
	username = _username
	
	clearBattles()
	
	Network.sendData({"type":"battleLog", "username":username})
	
func clearBattles():
	for battle in $ScrollContainer/Battles.get_children():
		if battle.name != "ShowMore":
			battle.queue_free()
	
func dataRecieved(data:Dictionary):
	
	match data.type:
		"battleLog":
			$Error.hide()
			for battle in data.battles.keys():
				addBattle(battle, data.battles[battle])
		"battleLogError":
			$Error/Message.text = data.error
			$Error.show()

func addBattle(id:String, stats:Dictionary):
	if $"%Battles".has_node(id):
		return
	var b = PastBattle.instance()
	b.name = id
	$"%Battles".add_child(b)
	b.setup(stats, stats.players[username].team)
	$"%Battles".move_child($"%Battles/ShowMore", $"%Battles".get_child_count()-1)

func playerSelected(_username:String):
	$"../../../".requestPlayerStats(_username)


func _on_ShowMore_pressed() -> void:
	emit_signal("showMore")
	Network.sendData({"type":"battleLog", "username":username, "start":$"%Battles".get_child_count()-1, "end":$"%Battles".get_child_count()+4})
