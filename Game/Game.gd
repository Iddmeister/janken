extends Node

class_name Game

var playerKey:String
var players:Dictionary = {}
var playerIDs:Dictionary = {}
var publicKeys:Dictionary = {}
var isServer:bool = false
var gameID:String
var map:Map

func _unhandled_input(event: InputEvent) -> void:
	if ((not get_tree().network_peer) or (not is_network_master())) and map.gameStarted:
		var newDir:Vector2 = Vector2(event.get_action_strength("right")-event.get_action_strength("left"),event.get_action_strength("down")-event.get_action_strength("up"))
		if newDir == Vector2(0, 0):
			return
		if newDir.abs().length() > 1:
			newDir.y = 0
		rpc_unreliable("playerInput", newDir)
		
remote func playerInput(dir:Vector2):
	if not get_tree().get_rpc_sender_id() in playerIDs:
		return
	var public:String = players[playerIDs[get_tree().get_rpc_sender_id()]].public
	map.playerInput(public, dir)
	

func _ready() -> void:
	
	map = $MapContainer/Map
	map.game = self
	
	if not OS.get_cmdline_args().empty():
		match OS.get_cmdline_args()[0]:
			"quickserver":
				isServer = true
				gameID = OS.get_cmdline_args()[1]

				for key in range(2, 8):
					players[OS.get_cmdline_args()[key]] = {"id":-1, "type":Player.SCISSORS, "public":String(key-2), "team":0 if key <= 4 else 1}
					
					match key:
						2:
							players[OS.get_cmdline_args()[key]].type = Player.ROCK
						3:
							players[OS.get_cmdline_args()[key]].type = Player.PAPER
						4:
							players[OS.get_cmdline_args()[key]].type = Player.SCISSORS
						5:
							players[OS.get_cmdline_args()[key]].type = Player.ROCK
						6:
							players[OS.get_cmdline_args()[key]].type = Player.PAPER
						7:
							players[OS.get_cmdline_args()[key]].type = Player.SCISSORS
					
					
					publicKeys[String(key-2)] = OS.get_cmdline_args()[key]
			"quickclient":
				playerKey = OS.get_cmdline_args()[3]
				joinServer(OS.get_cmdline_args()[1], int(OS.get_cmdline_args()[2]))
				
	if isServer:
		hostServer(5072)

func hostServer(port:int):
	var peer = NetworkedMultiplayerENet.new()
	peer.always_ordered = true
	peer.server_relay = false
	var err = peer.create_server(port, 6)
	if err != OK:
		print("Failed to create sever on port %s" % port)
		return
	print("Created server on port %s" % port)
	peer.connect("peer_connected", self, "peer_connected")
	peer.connect("peer_disconnected", self, "peer_disconnected")
	get_tree().network_peer = peer
	
func peer_connected(id:int):
	print("Peer %s Connected" % id)
	pass
	
func peer_disconnected(id:int):
	if id in playerIDs:
		print("Peer %s Disconnected" % id)
		players[playerIDs[id]].id = -2
		playerIDs.erase(id)
	
func joinServer(address:String, port:int):
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(address, port)
	peer.connect("connection_succeeded", self, "connection_succeeded")
	peer.connect("connection_failed", self, "connection_failed")
	peer.connect("server_disconnected", self, "server_disconnected")
	get_tree().network_peer = peer
	
func connection_succeeded():
	print("Connected to Server")
	rpc("authorizePlayer", playerKey)
	pass
	
func connection_failed():
	print("Failed to connect to server")
	pass
	
func server_disconnected():
	print("Server Disconnected")
	pass
	
remote func authorizePlayer(key:String):
	
	var id:int = get_tree().get_rpc_sender_id()
	
	if key in players.keys():
		if not (players[key].id == -1 or players[key].id == -2):
			print("Peer %s tried to connect to key %s but Peer %s is already connected" % [id, key, players[key].id])
			get_tree().network_peer.disconnect_peer(id, true)
			return
		print("Peer %s authorized with key %s" % [id, key])
		playerAuthorized(key, id)
		
	else:
		get_tree().network_peer.disconnect_peer(id, true)
		print("Disconnected Unauthorized Peer %s" % id)
		
func playerAuthorized(key:String, id:int):
	
	if players[key].id == -2:
		reconnectPlayer(key, id)
	
	players[key].id = id
	playerIDs[id] = key
	var test:int = 0
	for player in players.keys():
#		if players[player].id == -1:
#			return
		if not players[player].id == -1:
			test += 1
	if test >= 2:
		map.rpc("startGame")
		
func reconnectPlayer(key:String, id:int):
	#Sync world state
	pass
	
