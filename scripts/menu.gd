extends Control


func _on_host_pressed():
	get_node("/root/server").host(get_node("net/address").get_text(), get_node("net/port").get_text().to_int())
	get_node("host").set_disabled(true)

func _on_connect_pressed():
	get_node("/root/client").connect(get_node("net/address").get_text(), get_node("net/port").get_text().to_int())


func _on_campaign_pressed():
	get_node("/root/server").host(get_node("net/address").get_text(), get_node("net/port").get_text().to_int())
	get_node("host").set_disabled(true)
	get_node("/root/client").connect(get_node("net/address").get_text(), get_node("net/port").get_text().to_int())


func _on_HSlider_value_changed( value ):
	get_node("net/label5").set_text(str(value))
