extends Control

func setUsername(username:String):
	$"%Username".text = username

func setStats(stats:Dictionary):
	
	$CenterContainer.hide()
	$Stats.show()
	$"%CurrentRank".text = String(stats.currentRank if stats.currentRank else 0)
	$"%HighestRank".text = String(stats.highestRank if stats.highestRank else 0)
	$"%GamesPlayed".text = String(stats.games if stats.games else 0)
	$"%Winrate".text = String(floor(float(stats.wins)/stats.games*100))
	$"%AverageDots".text = String(floor(float(stats.dots)/stats.games))
	$"%KillVDeath".value = float(stats.kills)/stats.deaths
	
	var highest:String = "0"
	
	for type in stats.types.keys():
		if stats.types[type] > stats.types[highest]:
			highest = type
	
	$"%TypeDistro".value = float(stats.types[highest])/stats.games
	
	for child in $"%TypeGraphics".get_children():
		child.hide()
	
	$"%TypeGraphics".get_node(highest).show()
	
func loading():
	$CenterContainer.show()
	$Stats.hide()


func hide():
	.hide()
	for child in $"%TypeGraphics".get_children():
		child.hide()
		

