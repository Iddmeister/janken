extends Node

class_name Game

var privateKey:String
var public:String

var privateKeys:Dictionary = {}
var players:Dictionary = {}
var playerIDs:Dictionary = {}

var isServer:bool = false
var gameID:String
var map

var maps:Dictionary = {"main":"res://Maps/Main/MainMap.tscn"}

var matchInfo:Dictionary = {}

func _unhandled_input(event: InputEvent) -> void:
	if ((not get_tree().network_peer) or (not is_network_master())) and map and map.gameStarted:
		var newDir:Vector2 = Vector2(event.get_action_strength("right")-event.get_action_strength("left"),event.get_action_strength("down")-event.get_action_strength("up"))
		if newDir == Vector2(0, 0):
			return
		if newDir.abs().length() > 1:
			newDir.y = 0
		rpc_unreliable("playerInput", newDir)
		
remote func playerInput(dir:Vector2):
	if not get_tree().get_rpc_sender_id() in playerIDs:
		return
	var public:String = playerIDs[get_tree().get_rpc_sender_id()]
	map.playerInput(public, dir)
	
func loadMap(_map:String):
	
	var m = load(maps[_map]).instance()
	m.game = self
	$MapContainer.add_child(m)
	map = m
	
	pass
	

func _ready() -> void:
	

	if not OS.get_cmdline_args().empty():
		match OS.get_cmdline_args()[0]:
			"quickserver":
				isServer = true
				matchInfo.map = OS.get_cmdline_args()[1]
				gameID = OS.get_cmdline_args()[2]
				for key in range(0, 6):
					players[String(key)] = {"id":-1, "team":0 if key <= 2 else 1}
					players[String(key)].type = key if key <= 2 else key-3
					privateKeys["abcdef"[key]] = String(key)
					
				loadMap(matchInfo.map)
			
			"quickclient":
				privateKey = OS.get_cmdline_args()[3]
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
	rpc("authorizePlayer", privateKey)
	pass
	
func connection_failed():
	print("Failed to connect to server")
	pass
	
func server_disconnected():
	print("Server Disconnected")
	pass
	
remote func authorizePlayer(key:String):
	
	var id:int = get_tree().get_rpc_sender_id()
	
	if key in privateKeys.keys():
		var player = privateKeys[key]
		if not (players[player].id == -1 or players[player].id == -2):
			print("Peer %s tried to connect to key %s but Peer %s is already connected" % [id, key, players[player].id])
			get_tree().network_peer.disconnect_peer(id, true)
			return
		print("Peer %s authorized with key %s" % [id, key])
		playerAuthorized(key, id)
		
	else:
		get_tree().network_peer.disconnect_peer(id, true)
		print("Disconnected Unauthorized Peer %s" % id)
		
func playerAuthorized(key:String, id:int):
	var player = privateKeys[key]
	if players[player].id == -2:
		reconnectPlayer(key, id)
	
	players[player].id = id
	playerIDs[id] = player
	
	for playerID in playerIDs.keys():
		rpc_id(playerID, "playerJoined", player, matchInfo if playerID == id else {}, players if playerID == id else {})
	
	var test:int = 0
	
	for p in players.keys():
#		if playerKeys[player].id == -1:
#			return
		if not players[p].id == -1:
			test += 1
	if test >= 2:
		# This currently sends ids (may or may not want to do this but currently doesn' update on ids changing)
		map.rpc("startGame")
		
puppet func playerJoined(player:String, _matchInfo:Dictionary={}, playerInfo:Dictionary={}):
	if public.empty():
		public = player
	if players.empty():
		players = playerInfo
	if matchInfo.empty():
		matchInfo = _matchInfo
	if not map:
		loadMap(matchInfo.map)
		
func reconnectPlayer(key:String, id:int):
	#Sync world state
	pass
	