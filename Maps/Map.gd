extends Node2D

class_name Map

var gameStarted:bool = false
var PlayerScene = preload("res://Player/Player.tscn")

onready var gridPath = $GridPath
	
func _ready() -> void:
	for player in $Players.get_children():
		player.map = self
		player.gridPath = gridPath
		
	var placed:PoolVector2Array
		
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

func createPlayer(public:String, type:int, pos:Vector2) -> Player:
	var p:Player = PlayerScene.instance()
	p.name = public
	p.type = type
	p.gridPath = $GridPath
	p.map = self
	p.global_position = pos
	$Players.add_child(p)
	return p
	
puppetsync func respawnPlayer():
	pass
	
	
var Dot = preload("res://Collectibles/Dot/Dot.tscn")
	
func placeDot(pos:Vector2):
	var d = Dot.instance()
	d.global_position = pos
	$Collectibles.add_child(d)
	
