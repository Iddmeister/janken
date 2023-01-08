extends Node2D

signal respawnPlayer(player)

export var regenTime:float = 5
export var moveSpeed:float = 150

var angles:Array = [25, 45, 115, 135]

var players:Dictionary = {}
export var bounds:Rect2 = Rect2(Vector2(-49, -16), Vector2(96, 32))

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
	
	angles.shuffle()
	var angle = angles[0]
	
	var exitPos:Vector2 = Vector2(0, 0) #Vector2(0, bounds.size.y/2*(-1 if map.game.players[player].team == 0 else 1))
	
	var path = generateBouncePath(exitPos, deg2rad(angle), moveSpeed, regenTime)
	path.invert()
	var p = respawningPlayer.instance()
	p.name = player
	p.speed = moveSpeed
	p.path = path
	p.position = path[0]
	if (not is_network_master()):
		p.setEnemy(not (map.game.players[map.game.me].team == map.game.players[player].team))
	$Players.add_child(p)
	
	if map:
		p.setType(map.game.players[player].type)
	else:
		p.setType(2)
	
puppetsync func exitChamber(player:String):
	var p = $Players.get_node(player)
	var team = map.game.players[player].team
	p.path = []
	p.exiting = true
	p.exitAngle = PI/2 if team == 1 else -PI/2
	var t = create_tween().bind_node(self)
	t.tween_property(p, "position", get_node(String(team)).position, 1)
	if is_network_master():
		t.tween_callback(self, "respawnPlayer", [player])
	t.tween_callback(p, "queue_free")
	
func respawnPlayer(player:String):
	emit_signal("respawnPlayer", player)
	
func _process(delta: float) -> void:
	if (not get_tree().network_peer) or (not is_network_master()):
		return
	for player in players.keys():
		players[player] -= delta
		if players[player] <= 0:
			players.erase(player)
			rpc("exitChamber", player)
			
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
			
			var i = Geometry.segment_intersects_segment_2d(currentPosition, currentPosition+(direction*totalDistance), start, end)
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
		
		
		
