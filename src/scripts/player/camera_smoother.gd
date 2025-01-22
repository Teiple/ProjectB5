extends Node3D

@export var max_distance := 0.4
@export var smooth_speed := 45.0
@export var enabled := false

@onready var player : Player = owner

func _ready():
	top_level = enabled
	if !enabled:
		set_process(false)
		transform = Transform3D.IDENTITY

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var target_position = get_parent().to_global(Vector3.ZERO)
	global_position = global_position.lerp(target_position, 1.0 - pow(0.5, smooth_speed * delta))
	global_rotation = get_parent().global_rotation
