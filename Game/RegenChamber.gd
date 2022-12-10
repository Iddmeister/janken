extends Node2D

signal respawnPlayer(player)

export var regenTime:float = 5
export var moveSpeed:float = 150
export var angleRange:float = 160

var players:Dictionary = {}
var bounds:Rect2 = Rect2(Vector2(-49, -16), Vector2(96, 32))

var respawningPlayer = preload("res://Game/RespawningPlayer.tscn")

var map

#func _draw() -> void:
#	draw_rect(bounds, Color(1, 0, 0, 1), false, 3)
#
#	for line in lines:
#		draw_line(line[0], line[1], Color(0, 1, 0, 1), 5)
#
#	draw_polyline(drawPath, Color(0, 0, 1))
#
#	draw_line(lines[0][0], lines[0][1], Color(1, 0, 0), 5)
#
#	draw_line(Vector2(0, -100), Vector2(0, -100)+Vector2(-1, 0), Color(0, 1, 1), 3)
#
#	draw_circle(Geometry.line_intersects_line_2d(lines[0][0], (lines[0][1]-lines[0][0]).normalized()*1000, Vector2(0, -100), Vector2(-1, 0)), 5, Color(1, 0, 0, 1))
#
onready var lines = [
			[bounds.position, Vector2(bounds.position.x, bounds.position.y+bounds.size.y)], 
			[Vector2(bounds.position.x, bounds.position.y+bounds.size.y), Vector2(bounds.position.x+bounds.size.x, bounds.position.y+bounds.size.y)],
			[Vector2(bounds.position.x+bounds.size.x, bounds.position.y+bounds.size.y), Vector2(bounds.position.x+bounds.size.x, bounds.position.y)],
			[Vector2(bounds.position.x+bounds.size.x, bounds.position.y), bounds.position]
			]

puppetsync func regenPlayer(player:String):
	if get_tree().network_peer and is_network_master():
		players[player] = regenTime
	
	randomize()
	var path = generateBouncePath(Vector2(0, -bounds.size.y/2), rand_range(PI/2-(deg2rad(angleRange/2)), PI/2+(deg2rad(angleRange/2))), moveSpeed, regenTime)
	path.invert()
	var p = respawningPlayer.instance()
	p.path = path
	p.position = path[0]
	$Players.add_child(p)
	
	if map:
		p.setType(map.game.players[player].type)
	else:
		p.setType(2)
	
	p.connect("finished", p, "queue_free")
	
	
func _process(delta: float) -> void:
	if (not get_tree().network_peer) or (not is_network_master()):
		return
	for player in players.keys():
		players[player] -= delta
		if players[player] <= 0:
			players.erase(player)
			emit_signal("respawnPlayer", player)
			
func generateBouncePath(startPos:Vector2, angle:float, speed:float, time:float):
	var totalDistance:float = speed*time
	var direction = Vector2(1, 0).rotated(angle)
	var currentPosition:Vector2 = startPos
	var path:PoolVector2Array = [currentPosition]
	var lastLine:Array
	while totalDistance > 0:
		
		var intersection = null
		
		for line in lines:
			if line == lastLine:
				continue
			var start = line[0]
			var end = line[1]
#
#			if (end-start).normalized() == (currentPosition-start).normalized():
#				continue
			
			var i = Geometry.segment_intersects_segment_2d(currentPosition, currentPosition+(direction*10000), start, end)
			if i:
				intersection = i
				direction = direction.bounce((end-start).normalized().tangent())
				lastLine = line
				break
				
		if not intersection:
			path.append(currentPosition+(direction*totalDistance))
			return path
		path.append(intersection)
		totalDistance -= (intersection-currentPosition).length()
		currentPosition = intersection
	return path
		
		
		
