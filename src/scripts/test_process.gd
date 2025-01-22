extends MeshInstance3D


var direction := 1.0
@onready var x_offset := global_position.x

func _process(delta: float) -> void:
	global_position.x += direction * 2.0 * delta
	if abs(global_position.x - x_offset) >= 10.0:
		direction *= -1.0
