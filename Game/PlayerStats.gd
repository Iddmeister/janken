extends Control

func setStats(stats:Dictionary):
	$CenterContainer.hide()
	$Stats.show()
	pass
	
func loading():
	$CenterContainer.show()
	$Stats.hide()
	pass
