extends Control

onready var pointContainer: HBoxContainer = $CenterContainer/VBoxContainer/PanelContainer/VBoxContainer/Points
onready var rankChange: HBoxContainer = $CenterContainer/VBoxContainer/PanelContainer/VBoxContainer/RankChange
onready var newRank: VBoxContainer = $CenterContainer/VBoxContainer/PanelContainer/VBoxContainer/NewRank
onready var loadingStats: Panel = $CenterContainer/VBoxContainer/PanelContainer/Loading

signal returnToLobby()

func _ready() -> void:
	Network.connect("data_recieved", self, "dataRecieved")
	
func dataRecieved(data:Dictionary):
	
	match data.type:
		
		"matchStats":
			setup(data.allyPoints, data.enemyPoints, data.rankChange, data.newRank)

func setup(allyPoints:int, enemyPoints:int, change:int, new:int):
	
	pointContainer.get_node("Ally").text = String(allyPoints)
	pointContainer.get_node("Enemy").text = String(enemyPoints)
	
	rankChange.get_node("Amount").text = String(change)+" RANK" if allyPoints != enemyPoints else "DRAW"
	rankChange.get_node("Sign").text = "-" if allyPoints < enemyPoints else ("+" if allyPoints > enemyPoints else "")
	
	rankChange.theme.set_color("font_color", "Label", Color(1, 0.74902, 0) if allyPoints > enemyPoints else (Color(1, 0.121569, 0.121569) if allyPoints < enemyPoints else Color(1, 1, 1)))
	
	newRank.get_node("Amount").text = String(new)
	
	loadingStats.hide()


func _on_Rematch_toggled(button_pressed: bool) -> void:
	pass # Replace with function body.

func _on_Continue_pressed() -> void:
	emit_signal("returnToLobby")
