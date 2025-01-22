extends Node3D
class_name ViewModel

@export_range(0.0, 180.0, 0.001, "radians_as_degrees") var max_sway_angle := deg_to_rad(10.0)
@export_range(0.0, 100.0, 0.001, "or_greater") var sway_speed := 5.0

@onready var weapon_controller : WeaponController = get_parent()

var current_sway_x := 0.0
var current_sway_y := 0.0

func _process(delta):
	var head : PlayerHead = weapon_controller.player.head
	current_sway_y = lerpf(current_sway_y, head.current_mouse_x, 1.0 - pow(0.5, sway_speed * delta))
	current_sway_y = clampf(current_sway_y, -max_sway_angle, max_sway_angle)
	
	current_sway_x = lerpf(current_sway_x, head.current_mouse_y, 1.0 - pow(0.5, sway_speed * delta))
	current_sway_x = clampf(current_sway_x, -max_sway_angle, max_sway_angle)
	
	rotation.x = current_sway_x
	rotation.y = current_sway_y
