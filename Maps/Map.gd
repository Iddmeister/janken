extends Node2D

class_name Map

var gameStarted:bool = false
var PlayerScene = preload("res://Player/Player.tscn")

onready var gridPath = $GridPath
	
func _ready() -> void:
	for player in $Players.get_children():
		player.map = self
		player.gridPath = gridPath
	
puppetsync func startGame():
	gameStarted = true
	
func playerInput(public:String, dir:Vector2):
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
	
	
