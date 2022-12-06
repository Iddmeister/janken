extends KinematicBody2D

class_name Player

const invalidPos:Vector2 = Vector2(9999, 9999)
export var speed:float = 200
enum {ROCK, PAPER, SCISSORS}
export var type:int = ROCK

var team:int
var aimDir:Vector2 = Vector2(-1, 0)
var moveDir:Vector2 = Vector2(-1, 0)

onready var currentRouter:Vector2 = position

onready var gridPath = get_parent()

func initialize():
	pass

func movement(delta:float):

	if gridPath.pathRouters[currentRouter].has(moveDir):
		var nextRouter:Vector2 = gridPath.pathRouters[currentRouter][moveDir]
		
		if aimDir == moveDir*-1:
			moveDir = aimDir
			currentRouter = nextRouter
			nextRouter = gridPath.pathRouters[currentRouter][moveDir]
		
		var nextMove:float = speed*delta
		
		if (nextRouter-position).length() <= nextMove:
			nextMove -= (nextRouter-position).length()
#			var collision = move_and_collide((nextRouter-position).length()*moveDir)
#			if collision:
#				return
#			This needs work - Nedd to use move and collide in case there is a enemy inbetween router and player
#			Breaks inside of small spaces for some reason
			position = nextRouter
			if aimDir in gridPath.pathRouters[nextRouter].keys():
				moveDir = aimDir
				currentRouter = nextRouter
			elif moveDir in gridPath.pathRouters[nextRouter].keys():
				currentRouter = nextRouter
		
		if (not moveDir in gridPath.pathRouters[nextRouter].keys()) and position == nextRouter:
			nextMove = 0
		
		var collision = move_and_collide(nextMove*moveDir)
	
	
func _physics_process(delta: float) -> void:
	
	var newDir = Vector2(Input.get_action_strength("right")-Input.get_action_strength("left"), Input.get_action_strength("down")-Input.get_action_strength("up"))
	if abs(newDir.x) == abs(newDir.y):
		newDir.y = 0
	aimDir = newDir if newDir.length() > 0 else aimDir
	
	movement(delta)

