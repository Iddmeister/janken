extends Node2D

class_name Map

export var matchTime:float = 3

var gameStarted:bool = false
var gameFinished:bool = false
var PlayerScene = preload("res://Player/Player.tscn")

var teamInfo:Dictionary = {0:{"points":0}, 1:{"points":0}}

onready var gridPath = $GridPath
onready var regenChamber = $RegenChamber
onready var pointContainer = $UI/Info/Points
onready var clock = $UI/Info/Time

var game

func _ready() -> void:
	
	updateClock()
	regenChamber.map = self
	
	var placed:PoolVector2Array
	
	for startPosition in $StartPositions.get_children():
		placed.append(startPosition.global_position)
		createPlayer(startPosition.name, startPosition.type, startPosition.team, startPosition.global_position, startPosition.startDirection)
		
	for line in $DotExludes.get_children():
		for point in line.points:
			placed.append(line.to_global(point))
	
	for line in $GridPath.get_children():
		for p in range(line.points.size()-1):
			var start:Vector2 = line.to_global(line.points[p])
			var end:Vector2 = line.to_global(line.points[p+1])
			for d in range(0, (end-start).length(), 16):
				var pos:Vector2 = start + (end-start).normalized()*d
				if not pos in placed:
					placeDot(pos)
					placed.append(pos)
					
	get_tree().call_group("Collectible", "connect", "collected", self, "addPoints")
					
puppetsync func gameReady():
	if is_network_master():
		$StartStall.start()
	$Loading.hide()
	$Ready.show()
	
puppetsync func startGame():
	$Ready.text = "Start"
	gameStarted = true
	$ReadyDelay.start()
	$Time.start()
	
puppetsync func endGame():
	gameFinished = true
	$Loading.hide()
	$Ready.hide()
	$GameOver.show()
	#get_tree().paused = true
	
func playerInput(public:String, dir:Vector2):
	if gameFinished:
		return
	if $Players.has_node(public):
		$Players.get_node(public).changeAimDirection(dir)

func createPlayer(public:String, type:int, team:int, pos:Vector2, dir:Vector2=Vector2(-1, 0)) -> Player:
	var p:Player = PlayerScene.instance()
	p.name = public
	p.team = team
	p.type = type
	p.gridPath = $GridPath
	p.map = self
	p.startDirection = dir
	p.global_position = pos
	if get_tree().network_peer and (not is_network_master()):
		p.setEnemy(not game.players[game.public].team == game.players[public].team)
	$Players.add_child(p)
	p.connect("died", self, "playerDied", [p.name, p.team])
	return p
	
func playerDied(player:String, team:int):
	teamInfo[0 if team == 1 else 1].points += 100
	updatePoints()
	regenChamber.regenPlayer(player)
	
puppetsync func respawnPlayer(public:String):
	var player = createPlayer(public, game.players[public].type, game.players[public].team, regenChamber.get_node(String(game.players[public].team)).global_position)

func updatePoints():
	if not is_network_master():
		var team:int = game.players[game.public].team
		pointContainer.get_node("Ally").text = String(teamInfo[team].points)
		pointContainer.get_node("Enemy").text = String(teamInfo[0 if team == 1 else 1].points)
	
var Dot = preload("res://Collectibles/Dot/Dot.tscn")
	
func placeDot(pos:Vector2):
	var d = Dot.instance()
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

func _on_Time_tick() -> void:
	matchTime -= 1
	updateClock()
	if matchTime <= 0:
		$Time.stop()
		if is_network_master():
			rpc("endGame")
