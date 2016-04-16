
extends Timer

signal on_target_select(target)

var is_selecting = false
var prev_selected_target = -1
var selected_target = -1

func _ready():
	set_process(true)

func _process(delta):
	if is_selecting:
		var target = int(ceil(get_time_left()))
		if target != prev_selected_target:
			emit_signal("on_target_select", target)
			prev_selected_target = target
			selected_target = target

func start_selecting(count):
	if count > 0:
		is_selecting = true
		selected_target = -1
		set_wait_time(count)
		start()

func cancel_selecting():
	is_selecting = false
	prev_selected_target = -1
	stop()