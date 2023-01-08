extends Node

class_name Game

signal gameEnded()

var privateKey:String
var me:String

var players:Dictionary = {}
var playerIDs:Dictionary = {}

var isServer:bool = false
var gameID:String
var map

var maps:Dictionary = {"main":"res://Maps/Main/MainMap.tscn"}

#Contains map and port
var matchInfo:Dictionary = {}

func _unhandled_input(event: InputEvent) -> void:
	if get_tree().network_peer and (not is_network_master()) and map and map.gameStarted:
		var newDir:Vector2 = Vector2(event.get_action_strength("right")-event.get_action_strength("left"),event.get_action_strength("down")-event.get_action_strength("up"))
		if newDir == Vector2(0, 0):
			return
		if newDir.abs().length() > 1:
			newDir.y = 0
		rpc_unreliable("playerInput", newDir)
		
remote func playerInput(dir:Vector2):
	if not get_tree().get_rpc_sender_id() in playerIDs:
		return
	var username:String = playerIDs[get_tree().get_rpc_sender_id()]
	map.playerInput(username, dir)
	
func loadMap(_map:String):
	
	print("Loading Map %s" % _map)
	var m = load(maps[_map]).instance()
	if not m:
		print_debug("Error Loading Map %s" % _map)
		return
	m.game = self
	$MapContainer.add_child(m)
	map = m
	map.connect("gameEnded", self, "closeGame", [true])
	print("Success")
	
func removeMap():
	if $MapContainer.get_child_count() > 0:
		$MapContainer.get_child(0).queue_free()
	map = null

func _ready() -> void:
	
	print("Running")
	
	if not OS.get_cmdline_args().empty():
		
		if OS.get_cmdline_args()[0] == "--server":
				print("Starting Server")
				isServer = true
				gameID = OS.get_cmdline_args()[1]
				print("Attempting to Connect to Server")
				Network.connect("data_recieved", self, "dataRecieved")
				Network.connect("connection_established", self, "authenticateServer")
				Network.connectToServer()
	
func authenticateServer():
	print("Authenticating Server")
	Network.sendData({"type":"gameConnect", "id":gameID})
	
func dataRecieved(data:Dictionary):
	match data.type:
		"matchInfo":
			matchInfo = {}
			matchInfo.port = data.matchInfo.port
			matchInfo.map = data.matchInfo.map
			
			var newPlayers = data.matchInfo.players
			for player in newPlayers.keys():
				players[player] = {"team":newPlayers[player].team, "type":newPlayers[player].type, "id":-1, "key":newPlayers[player].key}
			
			loadMap(matchInfo.map)
			map.spawnPlayers()
			hostServer(matchInfo.port)

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
	if map and map.gameStarted:
		if playerIDs.keys().size() <= 0 and not map.gameFinished:
			$DisconnectDelay.start()
		else:
			$DisconnectDelay.stop()
			
	
func joinServer(address:String, port:int):
	print("Attempting to Connect to Game Server at %s on port %s" % [address, port])
	var peer = NetworkedMultiplayerENet.new()
	var err = peer.create_client(address, port)
	if err != OK:
		print("Failed to Connect to Game")
		return
	peer.connect("connection_succeeded", self, "connection_succeeded")
	peer.connect("connection_failed", self, "connection_failed")
	peer.connect("server_disconnected", self, "server_disconnected")
	get_tree().network_peer = peer
	
func connection_succeeded():
	print("Connected to Server")
	rpc("authorizePlayer", privateKey)
	pass
	
func connection_failed():
	print("Failed to connect to server")
	pass
	
func server_disconnected():
	print("Server Disconnected")
	pass
	
remote func authorizePlayer(key:String):
	
	print("Attempting to Authorize Player %s" % key)
	
	var id:int = get_tree().get_rpc_sender_id()
	
	var player:String = "none"
	
	for username in players.keys():
		if players[username].key == key:
			player = username
			break
	
	if player != "none":
		if not (players[player].id == -1 or players[player].id == -2):
			print("Peer %s tried to connect to key %s but Peer %s is already connected" % [id, key, players[player].id])
			get_tree().network_peer.disconnect_peer(id, true)
			return
		print("Peer %s authorized with key %s" % [id, key])
		playerAuthorized(player, id)
		
	else:
		get_tree().network_peer.disconnect_peer(id, true)
		print("Disconnected Unauthorized Peer %s" % id)
		
func playerAuthorized(player:String, id:int):
	if players[player].id == -2:
		reconnectPlayer(player, id)
	
	players[player].id = id
	playerIDs[id] = player
	
	for playerID in playerIDs.keys():
		if playerID == id:
			#Send all player data
			var data = {"players":{}, "map":matchInfo.map}
			for p in players.keys():
				data.players[p] = {"team":players[p].team, "type":players[p].type}
			rpc_id(playerID, "playerJoined", player, data)
		else:
			#Only send player who joined data
			var data = {"team":players[player].team, "type":players[player].type}
			rpc_id(playerID, "playerJoined", player, data)
	
	var test:int = 0
	
	for p in players.keys():
		if not players[p].id == -1:
			test += 1
	if test >= 2:
		map.rpc("gameReady")
		
puppet func playerJoined(player:String, data:Dictionary={}):
	
	if player == me:
		players = data.players
		matchInfo.map = data.map
	else:
		players[player] = data
	
	if not map:
		loadMap(matchInfo.map)
		map.spawnPlayers()
		
func reconnectPlayer(key:String, id:int):
	#Sync world state
	pass
	
func closeGame(stats:Dictionary={}, clean:bool=true):
	print("Game Ended")
	if is_network_master():
		Network.sendData({"type":"endGame", "clean":clean, "stats":stats})
		get_tree().paused = true
	else:
		emit_signal("gameEnded")
		get_tree().network_peer.call_deferred("close_connection")
		get_tree().network_peer = null
		removeMap()
		players = {}
		playerIDs = {}
		matchInfo = {}
	


func _on_DisconnectDelay_timeout() -> void:
	closeGame({}, false)
