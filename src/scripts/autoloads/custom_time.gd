extends Node
# An autoload to count the time has passed since the game started
# Unlike Time.get_ticks_msec(), the time will be the same for all nodes
# that query in the same process frame
var time := 0.0
var frame_count := 0
var physics_time := 0.0
var physics_frame_count := 0

func time_diff(another_time : float) -> float:
	return time - another_time

func _process(delta: float) -> void:
	time += delta
	frame_count += 1

func _physics_process(delta: float) -> void:
	physics_time += delta
	physics_frame_count += 1
