extends Node3D
class_name GrappleRope

@export var launch_curve : Curve
@export var normalized_launching_speed := 2.0
@export var max_amplitude := 1.0

@onready var mesh : MeshInstance3D = $Mesh

var offset := 0.0
var is_grappling := false
var end_point := Vector3.ZERO
var delay_for_animation := 0.0

func _process(delta):
	if is_grappling:
		mesh.visible = true
		look_at(end_point)
		mesh.scale.y = offset * (end_point - global_position).length()
		if offset < 1.0:
			offset += 1.0 / delay_for_animation * delta
			offset = clampf(offset, 0.0, 1.0)
			var amplitude = launch_curve.sample(offset) * max_amplitude
			mesh.get_surface_override_material(0).set("shader_parameter/rope_max_amplitude", amplitude)
			#mesh.get_surface_override_material(0).set("shader_parameter/y_scale", mesh.scale.y)
	else:
		mesh.visible = false

func start_grappling(grapple_point : Vector3, initial_delay : float):
	is_grappling = true
	end_point = grapple_point
	delay_for_animation = initial_delay
	offset = 0.0

func stop_grappling():
	is_grappling = false
	offset = 0.0
