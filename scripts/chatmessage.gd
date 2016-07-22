extends Control

var client
func _ready():
	set_process_input(true)
	
	client = get_node("/root/client")
	get_node("chatmessage").set_scroll_follow(true)

func _input(ev):
	if !get_node("textbox").has_focus() and ev.is_action_pressed("ui_accept"):
		get_node("textbox").show()
		get_node("textbox").grab_focus()
	elif get_node("textbox").has_focus() and ev.is_action_pressed("ui_accept"):
		if get_node("textbox").get_text().empty():
			return
		
		if client.connected:
			client.say(client.pid, get_node("textbox").get_text())
		else:
			add_msg(get_node("textbox").get_text())
		get_node("textbox").clear()
		
		get_node("textbox").hide()
		get_node("textbox").release_focus()
		
func add_msg(msg):
	get_node("chatmessage").add_text(msg + "\n")
