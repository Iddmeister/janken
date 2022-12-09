extends Node2D

class_name Map

var gameStarted:bool = false
var PlayerScene = preload("res://Player/Player.tscn")

var teamInfo:Dictionary = {0:{"points":0}, 1:{"points":0}}

onready var gridPath = $GridPath
onready var regenChamber = $RegenChamber

var game

func _ready() -> void:
	
	var placed:PoolVector2Array
	
	for player in $Players.get_children():
		player.map = self
		player.gridPath = gridPath
		player.connect("died", self, "playerDied", [player.name, player.team])
		placed.append(player.global_position)
		
	for line in $GridPath.get_children():
		for p in range(line.points.size()-1):
			var start:Vector2 = line.to_global(line.points[p])
			var end:Vector2 = line.to_global(line.points[p+1])
			for d in range(0, (end-start).length(), 16):
				var pos:Vector2 = start + (end-start).normalized()*d
				if not pos in placed:
					placeDot(pos)
					placed.append(pos)
	
puppetsync func startGame():
	gameStarted = true
	
func playerInput(public:String, dir:Vector2):
	if $Players.has_node(public):
		$Players.get_node(public).changeAimDirection(dir)

func createPlayer(public:String, type:int, team:int, pos:Vector2) -> Player:
	var p:Player = PlayerScene.instance()
	p.name = public
	p.team = team
	p.type = type
	p.gridPath = $GridPath
	p.map = self
	p.global_position = pos
	$Players.add_child(p)
	return p
	
func playerDied(player:String, team:int):
	teamInfo[0 if team == 1 else 1].points += 100
	updatePoints()
	regenChamber.regenPlayer(player)
	
puppetsync func respawnPlayer(public:String, type:int, team:int):
	var player = createPlayer(public, type, team, regenChamber.get_node(String(team)).global_position)
	player.map = self
	player.gridPath = gridPath
	player.connect("died", self, "playerDied", [player.name, player.team])
	
func updatePoints():
	$UI/Info/VBoxContainer/Points.text = String(abs(teamInfo[0].points-teamInfo[1].points))
	
var Dot = preload("res://Collectibles/Dot/Dot.tscn")
	
func placeDot(pos:Vector2):
	var d = Dot.instance()
	d.global_position = pos
	$Collectibles.add_child(d)
	d.connect("collected", self, "addPoints")
	
func addPoints(team:int, points:int):
	teamInfo[team].points += points
	updatePoints()
	

func _on_RegenChamber_respawnPlayer(player) -> void:
	var info = game.players[game.publicKeys[player]]
	rpc("respawnPlayer", player, info.type, info.team)
