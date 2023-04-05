extends Area2D

class_name Player

signal died(killer)

var Rock = preload("res://Player/Rock.tscn")
var Paper = preload("res://Player/Paper.tscn")
var Scissors = preload("res://Player/Scissors.tscn")

var Sparks = preload("res://Player/Sparks.tscn")
var DeathDebris = preload("res://Player/DeathDebris.tscn")

enum {ROCK, PAPER, SCISSORS}
enum {WIN, LOSE, DRAW}
export(int, "Rock", "Paper", "Scissors") var type:int = ROCK
export(int, "Team 1", "Team 2") var team:int
export var startDirection:Vector2 = Vector2(-1, 0)
onready var aimDir:Vector2 = startDirection
onready var moveDir:Vector2 = startDirection
export var speed:float = 150
export var drawKnockPower:float = 800
export var knockDeceleration:float = 0.2
export var enemyColour:Color
export var allyColour:Color
export var selfColour:Color
var currentKnockSpeed:float = 0
var knockedBy:Array = []

var gridPath
var map
var bot:bool = false

# Last router you passed through
onready var lastRouter:Vector2 = position
var nextRouter:Vector2

#Puppet Properties
onready var actualPos:Vector2 = global_position
export var syncSpeed:float = 0.5

var validMoveDirections = [Vector2(-1, 0), Vector2(1, 0), Vector2(0, 1), Vector2(0, -1)]

func _ready() -> void:
	$Graphics.global_rotation = startDirection.angle()
	match type:
		ROCK:
			$Graphics.add_child(Rock.instance())
		PAPER:
			$Graphics.add_child(Paper.instance())
		SCISSORS:
			$Graphics.add_child(Scissors.instance())
			
func changeAimDirection(dir:Vector2):
	if dir in validMoveDirections:
		aimDir = dir

func movement(delta:float):
	
	nextRouter = gridPath.paths[lastRouter][moveDir]
	
	var nextMove:float
	
	if currentKnockSpeed > 0:
		currentKnockSpeed = max(lerp(currentKnockSpeed, 0, knockDeceleration*delta*60), speed/2)
		if currentKnockSpeed <= speed/2:
			currentKnockSpeed = 0
		nextMove = currentKnockSpeed*delta
	else:
		
		if not knockedBy.empty():
			knockedBy.clear()
		
		nextMove = speed*delta
	
		if aimDir == moveDir*-1:
			moveDir = aimDir
			lastRouter = nextRouter
			nextRouter = gridPath.paths[lastRouter][moveDir]
			$Graphics.global_rotation = moveDir.angle()
	
	if (nextRouter-position).length() <= nextMove:
		nextMove -= (nextRouter-position).length()
		position = nextRouter
		
		if (aimDir in gridPath.paths[nextRouter].keys()) and not currentKnockSpeed > 0:
			moveDir = aimDir
		if moveDir in gridPath.paths[nextRouter].keys():
			lastRouter = nextRouter
			nextRouter = gridPath.paths[lastRouter][moveDir]
		else:
			nextMove = 0
			
	position += nextMove*moveDir
	
	$Graphics.global_rotation = lerp_angle($Graphics.global_rotation, moveDir.angle(), 0.35*delta*60)
	
	
puppet func updatePosition(pos:Vector2, dir:Vector2):
	
	actualPos = pos
	if dir == moveDir*-1:
			$Graphics.global_rotation = dir.angle()
	moveDir = dir
	
func syncPosition(delta:float):
	position = position.linear_interpolate(actualPos, syncSpeed*delta*60)
	$Graphics.global_rotation = lerp_angle($Graphics.global_rotation, moveDir.angle(), 0.35*delta*60)

func _physics_process(delta: float) -> void:
	
	if (not get_tree().network_peer) or (not map.gameStarted) or map.gameFinished:
		return
	
	if is_network_master():
		movement(delta)
		rpc_unreliable("updatePosition", position, moveDir)
	else:
		syncPosition(delta)
	
puppetsync func kill(killer:String):
	emit_signal("died", killer)
	var d = DeathDebris.instance()
	get_parent().add_child(d)
	d.global_position = global_position
	queue_free()
	
func knock(power:float, dir:Vector2):
	
	currentKnockSpeed = power
	if dir == moveDir*-1:
		moveDir = dir
		lastRouter = nextRouter
		aimDir = moveDir
	elif position == nextRouter:
		if dir in gridPath.paths[nextRouter].keys():
			moveDir = dir
			aimDir = moveDir
			lastRouter = nextRouter
			
puppet func knockEffects(pos:Vector2):
		var s = Sparks.instance()
		get_parent().add_child(s)
		s.global_position = pos
	
func getOutcome(ally:int, enemy:int) -> int:
	
	if ally == enemy:
		return DRAW
		
	if (ally == SCISSORS and enemy == PAPER) or (ally == PAPER and enemy == ROCK) or (ally == ROCK and enemy == SCISSORS):
		return WIN
		
	return LOSE
	
func _on_Player_area_entered(area: Area2D) -> void:
	
	if (not map.gameStarted) or (not is_network_master()) or map.gameFinished:
		return
	
	if not area.is_in_group("Player"):
		return
	
	if not area.team == team:
		
		var outcome:int = getOutcome(type, area.type)
		
		match outcome:
			WIN:
				area.rpc("kill", name)
			DRAW:
				if not (area in knockedBy):
					knockedBy.append(area)
					var knockDir = (area.position-position).normalized().round()
					if abs(knockDir.x) == abs(knockDir.y):
						knockDir.y = 0
					area.knock(drawKnockPower, knockDir)
					
					if area.team == 0:
						rpc("knockEffects", global_position+((area.global_position-global_position)/2))
