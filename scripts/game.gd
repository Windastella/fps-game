# This script handle all game mode related
extends Node

export var view_sensitivity = 0.3

const MODE_FFA = 0
const MODE_SP = 1
const MODE_MSP = 2
const MODE_DM = 3

var player 

func _ready():
	set_process_input(true)
	
func _input(ie):
	if get_node("/root/client").connected:
		if ie.type == InputEvent.MOUSE_MOTION:
			var yaw = rad2deg(get_node("/root/client").localplayer.get_node("body").get_rotation().y)
			var pitch = rad2deg(get_node("/root/client").localplayer.get_node("body/cam").get_rotation().x)
		
			yaw = fmod(yaw - ie.relative_x * view_sensitivity, 360)
			pitch = max(min(pitch - ie.relative_y * view_sensitivity, 90), -90)
		
			get_node("/root/client").localplayer.get_node("body").set_rotation(Vector3(0, deg2rad(yaw), 0))
			get_node("/root/client").localplayer.get_node("body/cam").set_rotation(Vector3(deg2rad(pitch), 0, 0))

func game_update(gamemode = MODE_FFA):
	pass