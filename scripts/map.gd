extends Spatial

var loader = null
var wait_frames
var time_max = 100 # msec

class CScene:
	var path = ""
	var instance = null

var loaded_scene = [];

func _ready():
	return
		
func scene_load(path):
	for i in loaded_scene:
		if i.path == path:
			return i;
	
	var instance = load(path)
	var scene = CScene.new()
	scene.path = path
	scene.instance = instance
	loaded_scene.push_back(scene)
	return scene
	
func add_scene(path):
	var scene = scene_load(path)
	var target_scene = scene.instance.instance()
	var name = "obj_"+str(rand_range(99,999))
	
	while get_node(name) != null:
		randomize()
		name = "obj_"+str(rand_range(99,999))
	
	target_scene.set_name(name)
	add_child(target_scene)
	target_scene = get_node(name)
	return target_scene
	
func add_map(path):
	loader = ResourceLoader.load_interactive(path)
	if loader == null:
		get_node("/root/client").disconnected()
		print("Cannot find map...")
		return
	set_process(true)
	
	
	wait_frames = 1

func _process(delta):
	if loader == null:
		# no need to process anymore
		set_process(false)
		return
	if wait_frames > 0: # wait for frames to let the "loading" animation to show up
		wait_frames -= 1
		return
	
	var t = OS.get_ticks_msec()
	while OS.get_ticks_msec() < t + time_max:
		
		var err = loader.poll()
		if err == ERR_FILE_EOF:
			var resource = loader.get_resource()
			var target_scene = resource.instance()
			var name = "map"
	
			while get_node(name) != null:
				remove_child(get_node(name))
			
			loader = null
			target_scene.set_name(name)
			add_child(target_scene)
			target_scene = get_node(name)
			break
		elif err == OK:
			show_loading()
		else:
			get_node("/root/client").disconnected()
			print("Cannot find map...")
			break

func show_loading():
	var progress = float(loader.get_stage()) / loader.get_stage_count()
	print("Load progress:", progress)
	
func clear_map():
	var childs = get_children()
	for child in childs:
		remove_child(child)
	
	print("Map cleared...")
