
var timer = 0
var endtime = 0
var timeout = false

func start(time):
	timer = 0
	endtime = time
	timeout = false
	
func update(dt):
	timer += dt
	if timer > endtime:
		timeout = true
		
func is_timeout():
	return timeout

func get_countdown():
	if timeout:
		return 0
	return endtime - timer
	
func get_timer():
	if timeout:
		return endtime
	return timer