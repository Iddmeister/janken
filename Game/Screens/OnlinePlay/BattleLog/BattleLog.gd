extends Control

var PastBattle = preload("res://Screens/OnlinePlay/BattleLog/PastBattle.tscn")
var username:String

signal reachedBottom()

func addBattle(stats:Dictionary):
	var b = PastBattle.instance()
	$"%Battles".add_child(b)
	b.setup(stats, stats.players[username].team)

func _on_BottomNotifier_screen_entered() -> void:
	emit_signal("reachedBottom")
