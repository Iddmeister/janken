extends Area2D

class_name Player

const invalidPos:Vector2 = Vector2(9999, 9999)
export var speed:float = 200
export var knockForce:float = 500
export var knockDeceleration:float = 2000
enum {ROCK, PAPER, SCISSORS}
enum {WIN, LOSE, DRAW}
export var type:int = ROCK
export var team:int
export var radius:float = 16
var aimDir:Vector2 = Vector2(-1, 0)
var moveDir:Vector2 = Vector2(-1, 0)
var currentKnockSpeed:float = 0
var knockedBy:Array = []

onready var currentRouter:Vector2 = position

onready var gridPath = get_parent()

onready var collision:CollisionShape2D = $Collision

func getOutcome(ally:int, enemy:int) -> int:
	
	if ally == enemy:
		return DRAW
		
	if (ally == SCISSORS and enemy == PAPER) or (ally == PAPER and enemy == ROCK) or (ally == ROCK and enemy == SCISSORS):
		return WIN
		
	return LOSE


func initialize():
	pass

func movement(delta:float):

	if gridPath.pathRouters[currentRouter].has(moveDir):
		
		var nextRouter:Vector2 = gridPath.pathRouters[currentRouter][moveDir]
		
		var nextMove:float = speed*delta
		
		if currentKnockSpeed > 0:
			currentKnockSpeed = max(0, currentKnockSpeed-(knockDeceleration*delta))
			nextMove = currentKnockSpeed*delta
		else:
			knockedBy.clear()
			if aimDir == moveDir*-1:
				moveDir = aimDir
				currentRouter = nextRouter
				nextRouter = gridPath.pathRouters[currentRouter][moveDir]
	
		if (nextRouter-position).length() <= nextMove:
			var lastPos:Vector2 = position
#			position += calculateVelocity((nextRouter-position).length()*moveDir, get_tree().get_nodes_in_group("Player"))
			position += (nextRouter-position).length()*moveDir
			nextMove -= (position-lastPos).length()
			if (aimDir in gridPath.pathRouters[nextRouter].keys()) and not currentKnockSpeed > 0:
				print("good to go")
				moveDir = aimDir
				currentRouter = nextRouter
			elif moveDir in gridPath.pathRouters[nextRouter].keys():
				currentRouter = nextRouter
		
		if (not moveDir in gridPath.pathRouters[nextRouter].keys()) and position == nextRouter:
			nextMove = 0
		
#		print(moveWithCollision(nextMove*moveDir, get_tree().get_nodes_in_group("Player")))
#		position += calculateVelocity(nextMove*moveDir, get_tree().get_nodes_in_group("Player"))
		position += nextMove*moveDir
#		position += moveWithCollision(nextMove*moveDir, get_tree().get_nodes_in_group("Player"))
		
func calculateVelocity(original:Vector2, players:Array=[]):
	var finalVel:Vector2 = original
	for player in players:
		if player == self:
			continue
		var dist:Vector2 = (((original.normalized()*-radius)+player.position)-(position+(original.normalized()*radius)))
		
		
		if original.length() > dist.length():
			if dist.length() < finalVel.length():
				finalVel = dist.length()*original.normalized()
	return finalVel
	
func _physics_process(delta: float) -> void:
	
	var newDir:Vector2
	if name == "Player":
		newDir = Vector2(Input.get_action_strength("right")-Input.get_action_strength("left"), Input.get_action_strength("down")-Input.get_action_strength("up"))
	else:
		newDir = Vector2(Input.get_action_strength("test_right")-Input.get_action_strength("test_left"), Input.get_action_strength("test_down")-Input.get_action_strength("test_up"))
	
	if abs(newDir.x) == abs(newDir.y):
		newDir.y = 0
	aimDir = newDir if newDir.length() > 0 else aimDir
	
	movement(delta)
	
func knock(dir:Vector2, knocker=null):
	
	if knocker:
		if knocker in knockedBy:
			return
		knockedBy.append(knocker)
	
	currentKnockSpeed = knockForce
	if dir != moveDir:
		var nextRouter:Vector2 = gridPath.pathRouters[currentRouter][moveDir]
		currentRouter = nextRouter
	moveDir = dir

	
func kill():
	print("oof")

func _on_Player_area_entered(area: Area2D) -> void:
	
	if not area.team == team:
		
		var outcome:int = getOutcome(type, area.type)
		
		match outcome:
			WIN:
				area.kill()
			DRAW:
				area.knock((area.position-position).normalized(), self)
	
	
