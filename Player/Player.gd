extends Area2D

class_name Player

const invalidPos:Vector2 = Vector2(9999, 9999)
export var speed:float = 150
enum {ROCK, PAPER, SCISSORS}
enum {WIN, LOSE, DRAW}
export var type:int = ROCK
export var team:int
var aimDir:Vector2 = Vector2(-1, 0)
var moveDir:Vector2 = Vector2(-1, 0)

export var knockSpeed:float = 800
export var knockDeceleration:float = 0.2
var currentKnockSpeed:float = 0
var knockedBy:Array = []


onready var gridPath = get_parent()

# Last router you passed through
onready var lastRouter:Vector2 = position
var nextRouter:Vector2

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
	
	nextRouter = gridPath.pathRouters[lastRouter][moveDir]
	
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
			nextRouter = gridPath.pathRouters[lastRouter][moveDir]
	
	if (nextRouter-position).length() <= nextMove:
		nextMove -= (nextRouter-position).length()
		position = nextRouter
		
		if (aimDir in gridPath.pathRouters[nextRouter].keys()) and not currentKnockSpeed > 0:
			moveDir = aimDir
		if moveDir in gridPath.pathRouters[nextRouter].keys():
			lastRouter = nextRouter
			nextRouter = gridPath.pathRouters[lastRouter][moveDir]
		else:
			nextMove = 0
			
	position += nextMove*moveDir
	
	global_rotation = moveDir.angle()
	
func attemptMove(vel:Vector2):
	if aimDir in gridPath.pathRouters[lastRouter].keys():
		moveDir = aimDir
	if moveDir in gridPath.pathRouters[lastRouter].keys():
		position += vel
		

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
	
func kill():
	print("oof")
	
func knock(dir:Vector2, knocker=null):
	
	if knocker:
		if knocker in knockedBy:
			return
		knockedBy.append(knocker)
		
	currentKnockSpeed = knockSpeed
	if dir == moveDir*-1:
		moveDir = dir
		lastRouter = nextRouter
		aimDir = moveDir
	elif position == nextRouter:
		if dir in gridPath.pathRouters[nextRouter].keys():
			moveDir = dir
			aimDir = moveDir
			lastRouter = nextRouter
	
func _on_Player_area_entered(area: Area2D) -> void:
	
	if not area.team == team:
		
		var outcome:int = getOutcome(type, area.type)
		
		match outcome:
			WIN:
				area.kill()
			DRAW:
				var knockDir = (area.position-position).normalized().round()
				if abs(knockDir.x) == abs(knockDir.y):
					knockDir.y = 0
				area.knock(knockDir, self)
