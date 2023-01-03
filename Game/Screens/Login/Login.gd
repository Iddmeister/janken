extends Control

onready var status: Label = $CenterContainer/VBoxContainer/VBoxContainer2/Status
onready var usernameBox: LineEdit = $CenterContainer/VBoxContainer/VBoxContainer2/Username
onready var passwordBox: LineEdit = $CenterContainer/VBoxContainer/VBoxContainer2/Password

signal loggedIn(username)
signal cancelled()

func _ready() -> void:
	Network.connect("data_recieved", self, "dataRecieved")
	
func dataRecieved(data:Dictionary):
	
	match data.type:
		"loginError":
			status.text = data.error
			status.show()
		"loggedIn":
			emit_signal("loggedIn", data.username)
		"registered":
			pass

func checkDetails(username:String, password:String):
	if username.length() <= 0:
		status.text = "Please enter a Username"
		status.show()
		return false
	elif password.length() <= 0:
		status.text = "Please enter a Password"
		status.show()
		return false
	return true
		
func attemptLogin(username:String, password:String):
	if checkDetails(username, password):
		Network.sendData({"type":"login", "username":username, "password":password})
	

func _on_Login_pressed() -> void:
	status.hide()
	attemptLogin(usernameBox.text, passwordBox.text)


func _on_Register_pressed() -> void:
	if checkDetails(usernameBox.text, passwordBox.text):
		Network.sendData({"type":"register", "username":usernameBox.text, "password":passwordBox.text})

func _on_Cancel_pressed() -> void:
	hide()
	emit_signal("cancelled")


func _on_Username_text_entered(new_text: String) -> void:
	passwordBox.grab_focus()


func _on_Password_text_entered(new_text: String) -> void:
	attemptLogin(usernameBox.text, passwordBox.text)
