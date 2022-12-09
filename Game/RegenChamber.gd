extends Node2D

signal respawnPlayer(player)

export var regenTime:float = 3

var players:Dictionary = {}

puppetsync func regenPlayer(player:String):
	if is_network_master():
		players[player] = regenTime
	
func _process(delta: float) -> void:
	if not is_network_master():
		return
	for player in players.keys():
		players[player] -= delta
		if players[player] <= 0:
			players.erase(player)
			emit_signal("respawnPlayer", player)
