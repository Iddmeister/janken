extends PanelContainer

export var allyColour:Color
export var enemyColour:Color
export var winColour:Color
export var lossColour:Color
export var drawColour:Color

# Stats laid out as follows:
# {
#	team1 score
#	team2 score
#	date
#	team1Players {
#		(0)rock {username, kills, deaths, dots}
#		(1)paper
#		(2)scissors
# } 
#	team2Players {}
#
# }

func setup(stats:Dictionary, allyTeam:int=1):
	
	var allyScore:int = stats.team1Score if allyTeam == 1 else stats.team2Score
	var enemyScore:int = stats.team2Score if allyTeam == 1 else stats.team1Score
	
	$"%AllyPoints".text = String(allyScore)
	$"%EnemyPoints".text = String(enemyScore)
	
	if allyScore > enemyScore:
		$"%Outcome".text = "Won"
		$"%Outcome".add_color_override("font_color", allyColour)
		get_stylebox("panel").bg_color = winColour
	elif allyScore < enemyScore:
		$"%Outcome".text = "Loss"
		$"%Outcome".add_color_override("font_color", enemyColour)
		get_stylebox("panel").bg_color = lossColour
	else:
		$"%Outcome".text = "Draw"
		$"%Outcome".add_color_override("font_color", Color(1, 1, 1, 1))
		get_stylebox("panel").bg_color = drawColour
	
	
	for type in $"%PlayerEntries".get_children():
		
		var playerStats:Dictionary = stats.team1Players[int(type.name)]
		type.get_node("Players/Player1").setup(playerStats.username, playerStats.kills, playerStats.deaths, playerStats.dots, allyTeam == 1) 
		
		playerStats= stats.team2Players[int(type.name)]
		type.get_node("Players/Player2").setup(playerStats.username, playerStats.kills, playerStats.deaths, playerStats.dots, allyTeam == 2) 
	
#	setup({
#
#		"team1Score":600,
#		"team2Score":600,
#		"team1Players":{
#			0:{"username":"idd", "kills":10, "deaths":5, "dots":56},
#			1:{"username":"idd", "kills":10, "deaths":5, "dots":56},
#			2:{"username":"idd", "kills":10, "deaths":5, "dots":56},
#		},
#		"team2Players":{
#			0:{"username":"idd", "kills":10, "deaths":5, "dots":56},
#			1:{"username":"idd", "kills":10, "deaths":5, "dots":56},
#			2:{"username":"idd", "kills":10, "deaths":5, "dots":56},
#		}
#
#	}, 2)
