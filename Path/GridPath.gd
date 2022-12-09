tool

extends Node2D

class_name GridPath

export var drawPath:bool = false setget setDrawPath
const invalidPos:Vector2 = Vector2(9999, 9999)
var paths:Dictionary

func setDrawPath(val):
	if is_inside_tree():
		drawPath = val
		if drawPath:
			updatePaths()
		visible = drawPath
		update()

func _draw() -> void:
	if not drawPath:
		return
	for point in paths.keys():
		draw_circle(point, 10, Color(1, 0, 0, 1))
		for dir in paths[point].keys():
			draw_line(point, point+(dir*20), Color(1, 0, 0, 1), 5)
			
func updatePaths():
	var routers:Array = []
	for path in get_children():
		routers.append(generateRouters(path.points))
	paths = compoundRouters(routers)
	
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	updatePaths()


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
	
	
