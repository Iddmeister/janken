extends Area2D

class_name Player

const invalidPos:Vector2 = Vector2(9999, 9999)
export var speed:float = 200
enum {ROCK, PAPER, SCISSORS}
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
			position = nextRouter
			if aimDir in gridPath.pathRouters[nextRouter].keys():
				moveDir = aimDir
				currentRouter = nextRouter
			elif moveDir in gridPath.pathRouters[nextRouter].keys():
				currentRouter = nextRouter
#			elif not moveDir in gridPath.pathRouters[nextRouter].keys():
#				remainingMove = 0
		
		if (not moveDir in gridPath.pathRouters[nextRouter].keys()) and position == nextRouter:
			nextMove = 0
		
		position += nextMove*moveDir
	
	
#	if aimDir == moveDir*-1:
#		moveDir = aimDir
#
#	var nextRouter:Vector2
#
#	if gridPath.pathRouters[currentRouter].has(moveDir):
#		nextRouter = gridPath.pathRouters[currentRouter][moveDir]
#
#	var nextMove:Vector2 = speed*delta*moveDir
#
#	if (nextRouter-position).length() < nextMove.length():
#		var remainingMove = nextMove.length()-(nextRouter-position).length()
#		position = nextRouter
#		currentRouter = position
#		if aimDir in gridPath.pathRouters[nextRouter].keys():
#			moveDir = aimDir
#		elif not moveDir in gridPath.pathRouters[nextRouter].keys():
#			remainingMove = 0
#		position += moveDir*remainingMove
#	else:
#		position += nextMove
	
#	var nextRouter = gridPath.getClosestRouter(position, moveDir)
#
#	if nextRouter == invalidPos:
#		if (gridPath.pathRouters.has(position)) and (aimDir in gridPath.pathRouters[position].directions):
#			moveDir = aimDir
#			nextRouter = gridPath.getClosestRouter(position, moveDir)
#		else:
#			return
#
#	var nextMove:Vector2 = speed*delta*moveDir
#
#	if (nextRouter-position).length() < nextMove.length():
#		var remainingMove = nextMove.length()-(nextRouter-position).length()
#		position = nextRouter
#		if aimDir in gridPath.pathRouters[nextRouter].directions:
#			moveDir = aimDir
#		elif not moveDir in gridPath.pathRouters[nextRouter].directions:
#			remainingMove = 0
#		position += moveDir*remainingMove
#	else:
#		position += nextMove
	
	
#	if nextRouter and aimDir in gridPath.pathRouters[nextRouter].directions:
#		if (nextRouter-position).length() < nextMove.length():
#			var remainingMove = nextMove.length()-(nextRouter-position).length()
#			position = nextRouter
#			moveDir = aimDir
#			position += moveDir*remainingMove
#		else:
#			position += nextMove
#	elif nextRouter and not moveDir in gridPath.pathRouters[nextRouter].directions:
#		if (nextRouter-position).length() < nextMove.length():
#			var remainingMove = nextMove.length()-(nextRouter-position).length()
#			position = nextRouter
#			position += moveDir*remainingMove
#		else:
#			position += nextMove
#	else:
#		position += nextMove
	
	
	
func _physics_process(delta: float) -> void:
	
	var newDir = Vector2(Input.get_action_strength("right")-Input.get_action_strength("left"), Input.get_action_strength("down")-Input.get_action_strength("up"))
	if abs(newDir.x) == abs(newDir.y):
		newDir.y = 0
	aimDir = newDir if newDir.length() > 0 else aimDir
	
	movement(delta)
