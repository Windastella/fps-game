extends Control

var client
func _ready():
	set_process_input(true)
	
	client = get_node("/root/client")
	get_node("chatmessage").set_scroll_follow(true)

func _input(ev):
	if !get_node("textbox").has_focus() and ev.is_action_pressed("ui_chat"):
		get_node("textbox").show()
		get_node("textbox").grab_focus()
		set_opacity(1)
	elif get_node("textbox").has_focus() and ev.is_action_pressed("ui_chat"):
		if get_node("textbox").get_text().empty():
			return
		
		if client.connected:
			client.say(client.pid, get_node("textbox").get_text())
		else:
			add_msg(get_node("textbox").get_text())
		get_node("textbox").clear()
		
		get_node("textbox").hide()
		get_node("textbox").release_focus()
		set_opacity(0.7)
		
func add_msg(msg):
	get_node("chatmessage").get_v_scroll().hide()
	get_node("chatmessage").add_text(msg + "\n")


func _on_chatmessage_focus_enter():
	get_node("chatmessage").get_v_scroll().show()