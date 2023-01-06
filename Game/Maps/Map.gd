extends Node2D

class_name Map

export var matchTime:int = 120

var gameStarted:bool = false
var gameFinished:bool = false
var PlayerScene = preload("res://Player/Player.tscn")

var teamInfo:Dictionary = {0:{"points":0}, 1:{"points":0}}

onready var gridPath = $GridPath
onready var regenChamber = $RegenChamber
onready var pointContainer = $UI/Info/Points
onready var clock = $UI/Info/Time

var game

signal gameEnded(stats)

func _ready() -> void:
	
	updateClock()
	regenChamber.map = self
	
	var placed:PoolVector2Array
	
	for startPosition in $StartPositions.get_children():
		placed.append(startPosition.global_position)

	spawnDots(placed)
	
	get_tree().set_group("Spawner", "map", self)
	get_tree().call_group("Collectible", "connect", "collected", self, "addPoints")
	
func spawnPlayers():
	for player in game.players.keys():
		var startPosition = $StartPositions.get_node("%s%s" % [game.players[player].type, game.players[player].team])
		createPlayer(player, startPosition.type, game.players[player].team, startPosition.global_position, startPosition.startDirection)


puppetsync func spawnDots(exlude:PoolVector2Array=[]):
	
	var number:int = get_tree().get_nodes_in_group("Dot").size()
	var placed:PoolVector2Array = exlude
	
	for dot in get_tree().get_nodes_in_group("Dot"):
		placed.append(dot.global_position)
	for line in $DotExludes.get_children():
		for point in line.points:
			placed.append(line.to_global(point))
	for spawner in get_tree().get_nodes_in_group("Spawner"):
		placed.append(spawner.position)
			
	for line in $GridPath.get_children():
		for p in range(line.points.size()-1):
			var start:Vector2 = line.to_global(line.points[p])
			var end:Vector2 = line.to_global(line.points[p+1])
			for d in range(0, (end-start).length(), 16):
				var pos:Vector2 = start + (end-start).normalized()*d
				if not pos in placed:
					placeDot(pos, String(number))
					number += 1
					placed.append(pos)
					
					
puppetsync func gameReady():
	if is_network_master():
		$StartStall.start()
	$Loading.hide()
	$Ready.show()
	
puppetsync func startGame():
	print("Game Started")
	$Ready.text = "Start"
	gameStarted = true
	$ReadyDelay.start()
	$Time.start()
	
puppetsync func endGame():
	gameFinished = true
	$Loading.hide()
	$Ready.hide()
	$GameOver.show()
	$EndDelay.start()
	#get_tree().paused = true
	
func playerInput(username:String, dir:Vector2):
	if gameFinished:
		return
	if $Players.has_node(username):
		$Players.get_node(username).changeAimDirection(dir)

func createPlayer(username:String, type:int, team:int, pos:Vector2, dir:Vector2=Vector2(-1, 0)) -> Player:
	var p:Player = PlayerScene.instance()
	p.name = username
	p.team = team
	p.type = type
	p.gridPath = $GridPath
	p.map = self
	p.startDirection = dir
	p.global_position = pos
	if get_tree().network_peer and (not is_network_master()):
		p.setEnemy(not game.players[game.me].team == game.players[username].team)
	$Players.add_child(p)
	p.connect("died", self, "playerDied", [p.name, p.team])
	return p
	
func playerDied(player:String, team:int):
	teamInfo[0 if team == 1 else 1].points += 100
	updatePoints()
	regenChamber.regenPlayer(player)
	
puppetsync func respawnPlayer(username:String):
	var player = createPlayer(username, game.players[username].type, game.players[username].team, regenChamber.get_node(String(game.players[username].team)).global_position)

func updatePoints():
	if not is_network_master():
		var team:int = game.players[game.me].team
		pointContainer.get_node("Ally").text = String(teamInfo[team].points)
		pointContainer.get_node("Enemy").text = String(teamInfo[0 if team == 1 else 1].points)
	
var Dot = preload("res://Collectibles/Dot/Dot.tscn")
	
func placeDot(pos:Vector2, n:String=""):
	var d = Dot.instance()
	d.name = n if not n == "" else d.name
	d.global_position = pos
	$Collectibles.add_child(d)
	#d.connect("collected", self, "addPoints")
	
func addPoints(team:int, points:int):
	teamInfo[team].points += points
	updatePoints()
	

func _on_RegenChamber_respawnPlayer(player) -> void:
	rpc("respawnPlayer", player)


func _on_StartStall_timeout() -> void:
	rpc("startGame")


func _on_ReadyDelay_timeout() -> void:
	$Ready.hide()

func updateClock():
	clock.text = "%02d:%02d" % [floor(matchTime/60), matchTime-(60*floor(matchTime/60))]

func tick():
	pass

func _on_Time_tick() -> void:
	matchTime -= 1
	if is_network_master():
		tick()
	updateClock()
	if matchTime <= 0:
		$Time.stop()
		if is_network_master():
			rpc("endGame")


func _on_EndDelay_timeout() -> void:
	emit_signal("gameEnded", {0:teamInfo[0].points, 1:teamInfo[1].points})
