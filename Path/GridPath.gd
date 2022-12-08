extends Node2D

class_name GridPath

const invalidPos:Vector2 = Vector2(9999, 9999)
var pathRouters:Dictionary

func _draw() -> void:
	for point in pathRouters.keys():
		if point == $Player.lastRouter:
			draw_circle(point, 10, Color(0, 0, 1, 1))
		elif point == $Player.nextRouter:
			draw_circle(point, 10, Color(1, 0, 0, 1))
		for dir in pathRouters[point].keys():
			draw_line(point, point+(dir*20), Color(1, 0, 0, 1), 5)
			
func _physics_process(delta: float) -> void:
	update()
			
func _ready() -> void:
	var routers:Array = []
	for path in $Paths.get_children():
		routers.append(generateRouters(path.points))
	pathRouters = compoundRouters(routers)

func generateRouters(path:PoolVector2Array):
	
	var routers:Dictionary
	
	for p in range(path.size()):
		
		var point:Vector2 = path[p]
		
		if not routers.has(point):
			routers[point] = {}
		if p > 0:
			routers[point][(path[p-1]-point).normalized()] = path[p-1]
		if p < path.size()-1:
			routers[point][(path[p+1]-point).normalized()] = path[p+1]
	
	return routers
	
func compoundRouters(allRouters:Array):
	
	var final:Dictionary
	
	for routers in allRouters:
		
		if final.empty():
			final = routers
			continue
		
		for router in routers.keys():
			
			if final.has(router):
				for direction in routers[router].keys():
					if not final[router].has(direction):
						final[router][direction] = routers[router][direction]
			else:
				final[router] = routers[router]
				
	return final
	
func getClosestRouter(pos:Vector2, dir:Vector2=Vector2(0, 0)):
	
	if dir.length() == 0:
		var closest:Vector2 = pathRouters.keys()[0]
		for router in pathRouters.keys():
			if (router-pos).length() < (closest-pos).length():
				closest = router
			
		return closest
		
	var gotClosest:bool = false
	var closest:Vector2
	
	for router in pathRouters.keys():
		var rel = router-pos
		if rel.normalized() == dir:
			if (rel.length() < (closest-pos).length()) or not gotClosest:
				closest = router
				gotClosest = true
		else:
			continue
		
	return closest if gotClosest else invalidPos
	
	
