#Network code from https://github.com/khairul169/fps-test
#Edited by Nik "Windastella" Mirza

extends Node

var packet = null;
var peer = null;
var pid = -1;

var connected = false;
var netfps = 30.0;

class CClient:
	var connected = false;
	var node = null;
	
	# Player Variable
	var name = "Guy"

var client = []

const NET_PLAYER_VAR = 0
const NET_CHAT = 1
const NET_ACCEPTED = 2
const NET_CMD = 3
const NET_CLIENT_CONNECTED = 4
const NET_CLIENT_DISCONNECTED = 5
const NET_SRV_INIT = 6
const NET_UPDATE = 7
const NET_MAPCHANGE = 8

const CMD_SET_POS = 0
const CMD_SET_NAME = 1

var delay = 0.0

var m_game = null
var env = null
var hud = null
var menu = null
var localplayer = null

var vplayer = null

const MODE_FFA = 0
const MODE_SP = 1
const MODE_MSP = 2
const MODE_DM = 3

var mapname = "test"
var gamemode = MODE_FFA

func _ready():
	env = get_node("/root/main/env");
	m_game = get_node("/root/game")
	menu = get_node("/root/main/gui/menu")
	hud = get_node("/root/main/gui/hud")
	
	set_process_input(true);

func _input(ie):
	if ie.type == InputEvent.KEY:
		if ie.pressed && ie.scancode == KEY_ESCAPE && connected:
			if get_node("/root/server").hosted:
				get_node("/root/server").close_server()
			disconnected()

func disconnected():
	connected = false;
	peer.disconnect();
	print("Disconnecting...")
	menu.show()
	hud.hide()
	env.clear_map()
	
func connect(ip = "localhost", port = 3000):
	var address = GDNetAddress.new();
	address.set_host(ip);
	address.set_port(port);
	
	packet = GDNetHost.new()
	packet.bind()
	
	connected = false;
	var attempts = 0;
	
	while !connected && attempts < 10:
		peer = packet.connect(address);
		attempts += 1;
		OS.delay_msec(100);
		
		if (packet.is_event_available()):
			var event = packet.get_event()
			if (event.get_event_type() == GDNetEvent.CONNECT):
				print("Connected.");
				connected = true;
				break;
	
	if !connected:
		print("Failed Connecting to ",ip,":",str(port),".")
		disconnected()
	else:
		menu.hide();
		hud.show();
		
		localplayer = env.add_scene("res://assets/prefab/testplayer.scn")
		localplayer.set_name("player")
		
		set_process(true);

func _process(delta):
	if !connected:
		return;
	
	while packet.is_event_available():
		var event = packet.get_event();
		
		if event.get_event_type() == GDNetEvent.DISCONNECT:
			menu.show()
			hud.hide()
			env.clear_map()
			print("Client disconnected.")
			peer = null
			
		elif (event.get_event_type() == GDNetEvent.RECEIVE):
			var data = event.get_var();
			
			if data[0] == NET_ACCEPTED:
				pid = data[1];
				localplayer.PID = pid
				
			if data[0] == NET_CLIENT_CONNECTED:
				var vpid = data[1];
				
				var scn = env.add_scene("res:///assets/prefab/testplayer.scn");
				scn.set_name("vplayer_"+str(vpid));
				#get_node("/root/main/gui/ingame/map_overview").add_object(scn);
			
			if data[0] == NET_CLIENT_DISCONNECTED:
				var vpid = data[1];
				
				env.remove_child(env.get_node("vplayer_"+str(vpid)));
			
			if data[0] == NET_SRV_INIT:
				for i in data[1]:
					m_game.client_init(i)
					
			if data[0] == NET_MAPCHANGE:
				mapname = data[1]
				gamemode = data[2]
				env.add_map("res://assets/maps/" + mapname +".tscn")
				print("Map change to " + mapname)
				
			if data[0] == NET_UPDATE:
				for i in data[1]:
					m_game.client_receive_update(i, gamemode)
			
			if data[0] == NET_CMD:
				if data[1] == CMD_SET_POS:
					var player = env.get_node("player");
					var trans = player.get_global_transform();
					trans.origin = data[2];
					player.set_global_transform(trans);
				
				if data[1] == CMD_SET_NAME:
					var pid = data[2];
					var newname = data[3];
					
					var msg = str(pid) + " Changed his/her name to " + newname;
					if msg.length() > 32:
						msg = msg.substr(0, 32)+"..";
					get_node("/root/main/gui/hud/chatmessage").add_msg(msg);
			
			if data[0] == NET_CHAT:
				var msg = data[1];
				if msg.length() > 32:
					msg = msg.substr(0, 32)+"..";
				get_node("/root/main/gui/hud/chatmessage").add_msg(msg);
	
	if delay < 1.0/netfps:
		delay += delta;
		return;
	
	delay = 0.0;
	
	if !connected:
		return;
	
	#return;
	m_game.client_send_update()

func send_var(data, rel = false):
	if peer == null:
		return;
	
	var msg_type = GDNetMessage.UNSEQUENCED;
	if rel:
		msg_type = GDNetMessage.RELIABLE;
	
	peer.send_var(data, 0, msg_type);

func say(id, text):
	send_var([NET_CHAT, id, text], true);

