#Network code from https://github.com/khairul169/fps-test
#Edited by Nik "Windastella" Mirza
extends Node

var packet = null;
var hosted = false;

var time = 0.0;
var server;
var maxplayer = 32;

var update_time = 0.0;
var netfps = 30.0;

const MODE_FFA = 0
const MODE_SP = 1
const MODE_MSP = 2
const MODE_DM = 3

var mapname = "test"
var gamemode = MODE_FFA
var m_game = null

class CClient:
	var connected = false;
	var peer = null;
	var address = GDNetAddress.new();
	
	# Player Variable
	var name = "Player"
	var pos = Vector3()
	var rot = Vector3()
	var camrot = Vector3()
	var lv = Vector3()
	
	var hp = 100
	var st = true
	
var pclient = []

const NET_PLAYER_VAR = 0;
const NET_CHAT = 1;
const NET_ACCEPTED = 2;
const NET_CMD = 3;
const NET_CLIENT_CONNECTED = 4;
const NET_CLIENT_DISCONNECTED = 5;
const NET_SRV_INIT = 6;
const NET_UPDATE = 7
const NET_MAPCHANGE = 8

const CMD_SET_POS = 0
const CMD_SET_NAME = 1

const SRV_DATA_PLAYER = 0

func _ready():
	m_game = get_node("/root/game")
	
	var args = OS.get_cmdline_args();
	for i in args:
		if i == "-server":
			host();
			continue;

func _process(delta):
	if !hosted:
		return;
	
	time += delta;
	check_events();
	update_server();

func host(host = "localhost" ,port = 3000):
	if hosted:
		return;
	
	var address = GDNetAddress.new();
	address.set_host(host);
	address.set_port(port);

	packet = GDNetHost.new();
	var err = packet.bind(address);
	
	print(err);
	
	if !err:
		hosted = true;
		on_server_start();
		set_process(true);

func close_server():
	print("Disconnect all players...")
	disconnect_all()
	print("Shutting down server")
	var err = packet.unbind()
	
	print(err)
	
	if !err:
		hosted = false
		set_process(false)
		pclient = []
		print("All clients cleared.")
		
func check_events():
	while packet.is_event_available():
		var event = packet.get_event();
		on_event_received(event);

func update_server():
	if time < update_time:
		return;
	update_time = time + (1.0/netfps);
	
	m_game.server_send_update(gamemode)

func on_server_start():
	time = 0.0;
	
	mapname = get_node("/root/main/gui/menu/net/maplist").get_item_text(get_node("/root/main/gui/menu/net/maplist").get_selected())
	maxplayer = get_node("/root/main/gui/menu/net/label5").get_text().to_int()
	
	pclient.clear()
	pclient.resize(maxplayer)
	for i in range(0, pclient.size()):
		pclient[i] = CClient.new()
	
	set_process(true);
	print("Server started!")
	
func on_event_received(event):
	var peer = packet.get_peer(event.get_peer_id());
	
	if event.get_event_type() == GDNetEvent.CONNECT:
		var pid = get_empty_id();
			
		if pid != -1:
			pclient[pid].connected = true;
			pclient[pid].peer = peer
			pclient[pid].address = peer.get_address()
			
			send2c(pid, [], [NET_ACCEPTED, pid], true)
			send2c(pid, [], [NET_MAPCHANGE, mapname, gamemode], true)
			
			player_connected(pid);
		else:
			peer.disconnect()
			
		return
	
	elif event.get_event_type() == GDNetEvent.DISCONNECT:
		var pid = get_pid_from_peer(peer)
		if pid != -1:
			player_disconnected(pid)
			pclient[pid] = CClient.new()
		
		peer = null;
	
	elif event.get_event_type() == GDNetEvent.RECEIVE:
		m_game.server_receive_update(event, peer)
		
		return;

func check_player(pid, address = null):
	if pid != -1 && pclient[pid].connected:
		if address != null:
			if pclient[pid].address.get_host() != address.get_host() || pclient[pid].address.get_port() != address.get_port():
				return false;
		return true;
	return false;

func get_empty_id():
	for i in range(0, pclient.size()):
		if !check_player(i):
			return i;
	return -1;

func get_pid_from_peer(peer):
	for i in range(0, pclient.size()):
		if pclient[i].peer.get_peer_id() == peer.get_peer_id():
			return i;
	return -1;

func send2c(pid, excl, data, rel = false):
	var msg_type = GDNetMessage.UNSEQUENCED;
	if rel:
		msg_type = GDNetMessage.RELIABLE;
	
	if pid >= 0:
		if check_player(pid) && pclient[pid].peer != null:
			pclient[pid].peer.send_var(data, 0, msg_type);
	else:
		for i in range(0, pclient.size()):
			if !check_player(i) || i in excl || pclient[i].peer == null:
				continue;
			pclient[i].peer.send_var(data, 0, msg_type)
			
func disconnect_player(pid):
	if pid >= 0:
		if check_player(pid) && pclient[pid].peer != null:
			pclient[pid].peer.disconnect()
	else:
		for i in range(0, pclient.size()):
			if !check_player(i) || pclient[i].peer == null:
				continue
			pclient[i].peer.disconnect()

func disconnect_all():
	for i in range(0, pclient.size()):
		disconnect_player(i)
		
func player_connected(pid):
	var srv_data = [];
	
	# PLayer Data
	for id in range(0, pclient.size()):
		if check_player(id) && id != pid:
			srv_data.push_back([SRV_DATA_PLAYER, id]);
	
	send2c(pid, [], [NET_SRV_INIT, srv_data], true);
	
	send2c(-1, [pid], [NET_CLIENT_CONNECTED, pid], true);
	
	print(pclient[pid].name + " connected.");
	send2c(-1, [], [NET_CHAT, pclient[pid].name + " connected."], true);

func player_disconnected(pid):
	send2c(-1, [pid], [NET_CLIENT_DISCONNECTED, pid], true);
	
	print(pclient[pid].name + " disconnected.");
	send2c(-1, [pid], [NET_CHAT, pclient[pid].name + " disconnected."], true);

func parse_command(parser, cmd):
	if cmd[0] == "/unstuck":
		send2c(parser, [], [NET_CMD, CMD_SET_POS, Vector3()], true);
	if cmd[0] == "/setname" && cmd.size() > 1 && cmd[1] != "":
		send2c(-1, [], [NET_CMD, CMD_SET_NAME, parser, cmd[1]], true);
