extends Control

onready var joinStatus: Label = $JoinDialog/CenterContainer/VBoxContainer/Status

func _ready() -> void:
	Network.connect("data_recieved", self, "dataRecieved")
	
func dataRecieved(data:Dictionary):
	
	match data.type:
		
		"joinedTeam":
			$JoinDialog.hide()
			$Lobby.show()
			$Lobby.joinedTeam(data.code)
		"joinError":
			joinStatus.show()
			joinStatus.text = data.error

func joinTeam(code:String):
	joinStatus.hide()
	
	if code.length() <= 0:
		joinStatus.text = "Enter a Team Code"
		joinStatus.show()
		return
	
	Network.sendData({"type":"joinTeam", "code":code})

func _on_CreateTeam_pressed() -> void:
	Network.sendData({"type":"createTeam"})

func _on_JoinTeam_pressed() -> void:
	$JoinDialog/CenterContainer/VBoxContainer/Code.text = ""
	$JoinDialog.show()

func _on_Cancel_pressed() -> void:
	$JoinDialog.hide()

func _on_Join_pressed() -> void:
	joinTeam($JoinDialog/CenterContainer/VBoxContainer/Code.text)


func _on_Code_text_entered(new_text: String) -> void:
	joinTeam($JoinDialog/CenterContainer/VBoxContainer/Code.text)
