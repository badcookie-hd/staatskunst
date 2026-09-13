extends Node
signal updated
signal notice(message: String)
const Simulation = preload("res://scripts/simulation.gd")
var sim = Simulation.new()
var player_id = 0
var players: Dictionary = {}
var online = false
var running = false
var speed = 1
var elapsed = 0.0
var network_time = 0.0
var last_command: Dictionary = {}
const PORT = 24560

func _ready():
	sim.new_game()
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	multiplayer.connected_to_server.connect(func(): notice.emit("Verbunden. Der Host weist dir einen Staat zu."))
	multiplayer.connection_failed.connect(func(): disconnect_session(); notice.emit("Verbindung fehlgeschlagen. IP, UDP-Port 24560 und Firewall prüfen."))
	multiplayer.server_disconnected.connect(func(): disconnect_session(); notice.emit("Host getrennt. Die Partie ist pausiert und kann als Einzelspieler fortgesetzt werden."))

func is_host() -> bool:
	return not online or multiplayer.is_server()

func solo(id: int):
	disconnect_session()
	sim.new_game()
	player_id = id
	running = false
	elapsed = 0.0
	speed = 1
	updated.emit()

func host_game() -> Error:
	if online: return ERR_ALREADY_IN_USE
	var peer = ENetMultiplayerPeer.new()
	var result = peer.create_server(PORT, 7)
	if result != OK: return result
	multiplayer.multiplayer_peer = peer
	online = true
	players = {1: player_id}
	running = false
	notice.emit("LAN-Host bereit · UDP 24560 · Andere können per IP beitreten.")
	updated.emit()
	return OK

func join_game(address: String) -> Error:
	if address.strip_edges().is_empty(): return ERR_INVALID_PARAMETER
	disconnect_session()
	var peer = ENetMultiplayerPeer.new()
	var result = peer.create_client(address.strip_edges(), PORT)
	if result != OK: return result
	multiplayer.multiplayer_peer = peer
	online = true
	running = false
	notice.emit("Verbindung zu %s …" % address)
	return OK

func disconnect_session():
	if online: multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	online = false
	players.clear()
	last_command.clear()
	running = false
	updated.emit()

func _peer_connected(peer_id: int):
	if not is_host(): return
	var chosen = -1
	for id in range(8):
		if sim.alive(id) and id not in players.values(): chosen = id; break
	if chosen < 0:
		multiplayer.multiplayer_peer.disconnect_peer(peer_id)
		return
	players[peer_id] = chosen
	_assignment.rpc_id(peer_id, chosen)
	_sync.rpc_id(peer_id, sim.state, running, speed, players)
	notice.emit("Ein Spieler übernimmt %s." % sim.country(chosen).name)
	updated.emit()

func _peer_disconnected(peer_id: int):
	if not is_host(): return
	players.erase(peer_id)
	last_command.erase(peer_id)
	notice.emit("Spieler getrennt. Die KI übernimmt den Staat.")
	updated.emit()

@rpc("authority", "call_remote", "reliable")
func _assignment(id: int):
	player_id = id
	updated.emit()

@rpc("authority", "call_remote", "reliable")
func _sync(snapshot: Dictionary, active: bool, new_speed: int, roster: Dictionary):
	sim.state = snapshot
	running = active
	speed = new_speed
	players = roster
	updated.emit()

@rpc("authority", "call_remote", "reliable")
func _reply(message: String):
	notice.emit(message)

@rpc("any_peer", "call_remote", "reliable")
func _request(action: String, target: int):
	if not online or not multiplayer.is_server(): return
	var sender = multiplayer.get_remote_sender_id()
	if not players.has(sender) or action.length() > 40: return
	var now = Time.get_ticks_msec()
	if now - int(last_command.get(sender, -1000)) < 150: return
	last_command[sender] = now
	var result = sim.act(int(players[sender]), action, target)
	_reply.rpc_id(sender, result)
	broadcast()
	updated.emit()

func command(action: String, target: int = -1):
	if is_host():
		notice.emit(sim.act(player_id, action, target))
		broadcast()
		updated.emit()
	elif multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		_request.rpc_id(1, action, target)

func broadcast():
	if online and multiplayer.is_server(): _sync.rpc(sim.state, running, speed, players)

func toggle_pause():
	if not is_host(): return
	running = not running
	broadcast()
	updated.emit()

func set_speed(value: int):
	if not is_host(): return
	speed = clampi(value, 1, 5)
	broadcast()
	updated.emit()

func _process(delta: float):
	if not is_host(): return
	if running and int(sim.state.winner) < 0:
		elapsed += delta * speed
		if elapsed >= 1.0:
			elapsed -= 1.0
			sim.advance(players.values() if online else [player_id])
			if int(sim.state.winner) >= 0: running = false
			updated.emit()
	network_time += delta
	if network_time >= 1.0:
		network_time = 0
		broadcast()
