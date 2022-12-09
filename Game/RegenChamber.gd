extends Node2D

signal respawnPlayer(player)

export var regenTime:float = 3

var players:Dictionary = {}

func regenPlayer(player:String):
	players[player] = regenTime
	
func _process(delta: float) -> void:
	for player in players.keys():
		players[player] -= delta
		if players[player] <= 0:
			players.erase(player)
			emit_signal("respawnPlayer", player)
