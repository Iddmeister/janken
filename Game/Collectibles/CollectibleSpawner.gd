tool

extends Node2D

export var collectible:PackedScene setget setCollectible
export var customColour:Color = Color(1, 1, 1, 1)
var map
		
func setCollectible(val):
	collectible = val
	if collectible and Engine.is_editor_hint():
		if $Collectible.get_child_count() > 0:
			$Collectible.get_child(0).free()
		$Collectible.add_child(collectible.instance())
		
func _ready() -> void:
	$Circles.modulate = customColour
	if collectible and Engine.is_editor_hint():
		if $Collectible.get_child_count() > 0:
			$Collectible.get_child(0).free()
		$Collectible.add_child(collectible.instance())

puppetsync func spawn():
	if $Collectible.get_child_count() > 0:
		return
	if $Dot.get_child_count() > 0:
		$Dot.get_child(0).queue_free()
	$Animation.play("Spawn")
	
puppetsync func addCollectible():
	var c = collectible.instance()
	c.connect("collected", map, "playerScoredPoints")
	$Collectible.add_child(c)
	
func finishedTell():
	if is_network_master():
		rpc("addCollectible")
