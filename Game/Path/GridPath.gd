tool

extends Node2D

class_name GridPath

export var drawPath:bool = true setget setDrawPath
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
#	if not drawPath:
#		return
#	for point in paths.keys():
#		draw_circle(point, 10, Color(1, 0, 0, 1))
#		for dir in paths[point].keys():
#			draw_line(point, point+(dir*20), Color(1, 0, 0, 1), 5)
	pass
			
func updatePaths():
	var routers:Array = []
	for path in get_children():
		var points:Array = path.points
		for p in range(points.size()):
			points[p] = path.to_global(points[p])-global_position
		routers.append(generateRouters(points))
	paths = compoundRouters(routers)
	
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	updatePaths()


# Takes a path (array of points) and creates a router dictionary
# with every point as a key to a sub dictionary which contains
# every direction (Vector2) which can be travelled from the point
# as keys with the point to travel to as the value (Vector2)
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
	
	
	
# Takes an array of generated routers and combines them
# into a giant dictionary containing all points in the path
# and all the directions which can be travelled from each
# point to other points
func compoundRouters(allRouters:Array):
	
	var final:Dictionary
	
	for routers in allRouters:
		
		if final.empty():
			final = routers
			continue
		
		for point in routers.keys():
			
			if final.has(point):
				for direction in routers[point].keys():
					if not final[point].has(direction):
						final[point][direction] = routers[point][direction]
			else:
				final[point] = routers[point]
				
	return final
	
	
