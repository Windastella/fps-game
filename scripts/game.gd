# This script handle all game mode related
extends Node

const MODE_FFA = 0
const MODE_SP = 1
const MODE_MSP = 2
const MODE_DM = 3

const SRV_DATA_PLAYER = 0
const SRV_DATA_PHYSIC = 1

const NET_PLAYER_VAR = 0
const NET_CHAT = 1
const NET_ACCEPTED = 2
const NET_CMD = 3
const NET_CLIENT_CONNECTED = 4
const NET_CLIENT_DISCONNECTED = 5
const NET_SRV_INIT = 6
const NET_UPDATE = 7
const NET_MAPCHANGE = 8

var player
var pos
var rot
var camrot
var lv
var st

var env = null

var srv = null
var clt = null

func _ready():
	srv = get_node("/root/server")
	clt = get_node("/root/client")
	
	env = get_node("/root/main/env")

#Server side
func server_send_update(gamemode = MODE_FFA):
	
	#update all client connected to server
	for i in range(0, srv.pclient.size()):
		if !srv.check_player(i):
			continue;
			
		#update all players
		server_players_update(i)
		
func server_players_update(i):
	var srv_data = []
		
	for b in range(0, srv.pclient.size()):
		if !srv.check_player(b) || i == b:
			continue
		srv_data.push_back([SRV_DATA_PLAYER, b, srv.pclient[b].pos, srv.pclient[b].rot, srv.pclient[b].camrot, srv.pclient[b].lv,srv.pclient[b].st])
		
	srv.send2c(i, [], [srv.NET_UPDATE, srv_data])
	
#Server receive update
func server_receive_update(event, peer):
	var data = event.get_var();
	
	#for players update
	if data[0] == NET_PLAYER_VAR:
		var vpid = data[1];
		if srv.check_player(vpid, peer.get_address()):
			srv.pclient[vpid].pos = data[2]
			srv.pclient[vpid].rot = data[3]
			srv.pclient[vpid].camrot = data[4]
			srv.pclient[vpid].lv = data[5]
			srv.pclient[vpid].st = data[6]
	
	#For in game chat
	if data[0] == NET_CHAT:
		var vpid = data[1];
		var text = data[2];
		if srv.check_player(vpid, peer.get_address()) && text.length() > 0:
			if text.begins_with("/"):
				var array = text.split(" ", false);
				srv.parse_command(vpid, array);
			else:
				srv.send2c(-1, [], [NET_CHAT, "[Global] " + srv.pclient[vpid].name + ": "+text], true);

#Client side
func client_receive_update(data, gamemode = MODE_FFA):
	#print(data)
	#update from all client connected to server 
	if data[0] == SRV_DATA_PLAYER:
		var vpid = data[1]
		var vpos = data[2]
		var vrot = data[3]
		var vcamrot = data[4]
		var vlv = data[5]
		var vst = data[6]
		
		var node = env.get_node("vplayer_"+str(vpid))
		if node != null:
			node.PID = vpid
			node.set_translation(vpos)
			node.get_node("body").set_rotation(vrot)
			node.get_node("body/cam").set_rotation(vcamrot)
			node.set_linear_velocity(vlv)
			node.isAlive = vst

func client_init(data):
	if data[0] == SRV_DATA_PLAYER:
		var vpid = data[1];
		
		var scn = env.add_scene("res:///assets/prefab/testplayer.scn");
		scn.set_name("vplayer_"+str(vpid));
		#get_node("/root/main/gui/ingame/map_overview").add_object(scn);

func client_send_update():
		
	#local player update
	var data = []
	if (pos != clt.localplayer.get_translation() || rot != clt.localplayer.get_node("body").get_rotation() ||camrot != clt.localplayer.get_node("body/cam").get_rotation()|| lv != clt.localplayer.get_linear_velocity()):
		pos = clt.localplayer.get_translation()
		rot = clt.localplayer.get_node("body").get_rotation()
		camrot = clt.localplayer.get_node("body/cam").get_rotation()
		lv = clt.localplayer.get_linear_velocity()
		st = clt.localplayer.isAlive
		
		clt.send_var([NET_PLAYER_VAR, clt.pid, pos, rot, camrot, lv, st])