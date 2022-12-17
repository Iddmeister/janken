extends Collectible

func destroy():
	$Sprite.hide()
	$Points.text = String(points)
	$Points.show()
	$CollectDelay.start()

func _on_CollectDelay_timeout() -> void:
	queue_free()
