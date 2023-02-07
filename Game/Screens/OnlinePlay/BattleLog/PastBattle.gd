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
#	players {
#		username {team, type, kills, deaths, dots}
# } 
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
	
	for player in stats.players.keys():
		var playerStats = stats.players[player]
		$"%PlayerEntries".get_node(String(playerStats.type)).get_node("Players/Player%s" % playerStats.team).setup(player, playerStats.kills, playerStats.deaths, playerStats.dots, allyTeam == playerStats.team)
func _ready() -> void:
	setup({

		"team1Score":600,
		"team2Score":600,
		"players":{
			"idd":{"team":1, "type":0, "kills":10, "deaths":56, "dots":2},
			"idd2":{"team":1, "type":1, "kills":10, "deaths":56, "dots":2},
			"idd3":{"team":1, "type":2, "kills":10, "deaths":56, "dots":2},
			"idd4":{"team":2, "type":0, "kills":10, "deaths":56, "dots":2},
			"idd5":{"team":2, "type":1, "kills":10, "deaths":56, "dots":2},
			"idd6":{"team":2, "type":2, "kills":10, "deaths":56, "dots":2},
		}

	}, 2)
