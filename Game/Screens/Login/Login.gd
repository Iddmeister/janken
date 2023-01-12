extends Control

export var errorColour:Color = Color("ff2828")
export var correctColour:Color = Color("28ff3a")

onready var status: Label = $CenterContainer/VBoxContainer/VBoxContainer2/Status
onready var usernameBox: LineEdit = $CenterContainer/VBoxContainer/VBoxContainer2/Username
onready var passwordBox: LineEdit = $CenterContainer/VBoxContainer/VBoxContainer2/Password

signal loggedIn(username)
signal cancelled()

func _ready() -> void:
	Network.connect("data_recieved", self, "dataRecieved")
	
func showStatus(text:String, error:bool=true):
	status.text = text
	status.add_color_override("font_color", errorColour if error else correctColour)
	
func hideStatus():
	status.add_color_override("font_color", Color(1, 1, 1, 0))
	
	
func dataRecieved(data:Dictionary):
	
	match data.type:
		"loginError":
			showStatus(data.error)
		"loggedIn":
			emit_signal("loggedIn", data.username)
		"registered":
			showStatus("Account Created", false)
			pass

func checkDetails(username:String, password:String):
	if username.length() <= 0:
		showStatus("Please enter a Username")
		return false
	elif password.length() <= 0:
		showStatus("Please enter a Password")
		return false
	return true
		
func attemptLogin(username:String, password:String):
	if checkDetails(username, password):
		Network.sendData({"type":"login", "username":username, "password":password})
	

func _on_Login_pressed() -> void:
	hideStatus()
	attemptLogin(usernameBox.text, passwordBox.text)


func _on_Register_pressed() -> void:
	if checkDetails(usernameBox.text, passwordBox.text):
		Network.sendData({"type":"register", "username":usernameBox.text, "password":passwordBox.text})

func _on_Cancel_pressed() -> void:
	emit_signal("cancelled")


func _on_Username_text_entered(new_text: String) -> void:
	passwordBox.grab_focus()


func _on_Password_text_entered(new_text: String) -> void:
	attemptLogin(usernameBox.text, passwordBox.text)
