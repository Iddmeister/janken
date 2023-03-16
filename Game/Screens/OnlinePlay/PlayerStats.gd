extends Control

func showError(error:String):
	$CenterContainer.hide()
	$Stats.hide()
	$Error/Message.text = error
	$Error.show()
	

func setUsername(username:String):
	$"%Username".text = username
	
func clearStats():
	setStats({"currentRank":0, "highestRank":0, "games":0, "dots":0, "deaths":0, "kills":0, "types":{"0":0, "1":0, "2":0}})

func setStats(stats:Dictionary):
	
	$Error.hide()
	$CenterContainer.hide()
	$Stats.show()
	$"%CurrentRank".text = String(stats.currentRank if stats.currentRank else 0)
	$"%HighestRank".text = String(stats.highestRank if stats.highestRank else 0)
	$"%GamesPlayed".text = String(stats.games if stats.games else 0)
	$"%Winrate".text = String(floor(float(stats.wins)/stats.games*100))
	$"%AverageDots".text = String(floor(float(stats.dots)/stats.games))
	$"%KillVDeath".value = float(stats.kills)/(stats.deaths if stats.deaths != 0 else 1)
	
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
		

