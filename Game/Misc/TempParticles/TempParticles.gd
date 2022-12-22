extends CPUParticles2D

func _ready() -> void:
	emitting = true
	$Timer.wait_time = (lifetime/speed_scale)+1
	$Timer.start()
	
func _on_Timer_timeout() -> void:
	queue_free()
