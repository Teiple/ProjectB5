extends Camera3D

@export var speed := 0.5

func _process(delta):
	var fps = 1.0 / delta
	if fps < 40.0:
		print_debug("ow")
	global_position += global_basis.x * speed * delta
