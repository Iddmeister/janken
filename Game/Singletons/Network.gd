extends Node

export var serverURL = "127.0.0.1:5072"

var client = WebSocketClient.new()
var connected:bool = false

signal data_recieved(data)
signal connection_established()
signal connection_failed()
signal connection_lost()

func _ready():
	
	pause_mode = Node.PAUSE_MODE_PROCESS
	
	client.connect("connection_closed", self, "connection_closed")
	client.connect("connection_error", self, "connection_error")
	client.connect("connection_established", self, "connection_established")

	client.connect("data_received", self, "data_recieved")
	
	set_process(false)

func connectToServer():
	var err = client.connect_to_url(serverURL)
	if err != OK:
		print("Unable to connect to server - %s" % serverURL)
		set_process(false)
	else:
		set_process(true)
	return err
	
	
func connection_error():
	connected = false
	print("Unable to connect to server - %s" % serverURL)
	emit_signal("connection_failed")

func connection_closed(was_clean = false):
	connected = false
	print("Closed, clean: ", was_clean)
	emit_signal("connection_lost")
	set_process(false)

func connection_established(_proto = ""):
	
	connected = true
	
	print("Connected to Web Server")
	
	emit_signal("connection_established")
	
func sendData(data:Dictionary):
	client.get_peer(1).put_packet(JSON.print(data).to_utf8())

func data_recieved():
	emit_signal("data_recieved", JSON.parse(client.get_peer(1).get_packet().get_string_from_utf8()).result)

func _process(_delta):
	client.poll()
