extends Node3D
class_name PlayerHead

const  MOUSE_SENSITIVITY_SCALE = 0.1

@export var invert_y := false
@export var mouse_filter := false
@export var head_bobbing := false
@export_range(0.0, 100.0, 0.001) var mouse_smooth_speed := 30.0
@export_range(0.0, 100.0, 0.001) var mouse_sensitivity := 50.0
@export var head_stablize_speed := 20.0
@export var head_max_distance := 0.5
@export var head_height_offset := 0.1
@export var crouch_toggle_speed := 4.0
@export var head_bob_amplitude := 0.02
@export var head_bob_frequency_multiplier := 2.0

@onready var camera : Camera3D = %Camera
@onready var player : Player = get_parent()
@onready var head_bob = $HeadBob

var target_mouse_x := 0.0
var target_mouse_y := 0.0
var current_mouse_x := 0.0
var current_mouse_y := 0.0
var target_head_height := 0.0
var current_target_head_height := 0.0

var head_bob_x := 0.0
var head_bob_y_raw := 0.0
var update_time := UpdateTime.PROCESS_FRAME

enum UpdateTime{
	DEFAULT,
	PROCESS_FRAME,
	PHYSICS_FRAME
}

func change_update_time(update_t : UpdateTime):
	update_time = update_t

func _unhandled_input(event: InputEvent) -> void:
	if !Global.mouse_visible() && event is InputEventMouseMotion:
		# Mouse sensitivity should be the same regardless of the screen size
		# Update: There is now event.screen_relative(). But we should keep this
		# for backward compability 
		var screen_size = Global.get_screen_size()
		target_mouse_x = -(event.relative.x / screen_size.x) * mouse_sensitivity * MOUSE_SENSITIVITY_SCALE
		target_mouse_y = -(event.relative.y / screen_size.y) * mouse_sensitivity * MOUSE_SENSITIVITY_SCALE
		if invert_y:
			target_mouse_y *= -1
	
func _process(delta):
	if update_time in [UpdateTime.DEFAULT, UpdateTime.PROCESS_FRAME]:
		mouse_look(delta)

func _physics_process(delta: float) -> void:
	if update_time == UpdateTime.PHYSICS_FRAME:
		mouse_look(delta)

func mouse_look(delta):
	# Head bobbing
	if head_bobbing && player.state_machine.is_in_one_of_states(["Move/Run"]):
		head_bob_x += head_bob_frequency_multiplier * player.velocity.length() * delta
		head_bob_y_raw = sin(head_bob_x)
		var head_bob_y = (head_bob_y_raw - 1.0) * head_bob_amplitude
		head_bob.global_position = global_position
		head_bob.global_position.y = global_position.y + head_bob_y
	
	if mouse_filter:
		current_mouse_x = lerpf(current_mouse_x, target_mouse_x, 1.0 - pow(0.5, mouse_smooth_speed * delta))
		current_mouse_y = lerpf(current_mouse_y, target_mouse_y, 1.0 - pow(0.5, mouse_smooth_speed * delta))
	else:
		current_mouse_x = target_mouse_x
		current_mouse_y = target_mouse_y
	#print_debug(rotation_degrees)
	rotation.y = 0.0
	rotation.z = 0.0
	rotate_x(current_mouse_y)
	# Rotate x cause basis errors, the scale may be a few errors off from Vector3(1, 1, 1)
	# This caused all kind of problems, mainly for the physics engine
	scale = Vector3(1, 1, 1)
	
	player.rotate_local_y(current_mouse_x)
	rotation_degrees.x = clampf(rotation_degrees.x, -89, 89)
	target_mouse_x = 0.0
	target_mouse_y = 0.0
	
	# Use the height that is lower than the collider height a small amount 
	target_head_height = player.collision_shape.shape.height - head_height_offset
	# Use the linear smoothing here 'cause the lerping is very slow
	current_target_head_height = move_toward(current_target_head_height, target_head_height, crouch_toggle_speed * delta)
	# Clamping
	if abs(position.y - current_target_head_height) > head_max_distance:
		if position.y < current_target_head_height:
			position.y = current_target_head_height - head_max_distance
		else:
			position.y = current_target_head_height + head_max_distance
	# Lerping
	if abs(position.y - current_target_head_height) > 0.0001:
		position.y = lerpf(position.y, current_target_head_height, 1.0 - pow(0.5, head_stablize_speed * delta))
	else:
		position.y = current_target_head_height
	
func is_crouching_toggle_finished():
	return abs(current_target_head_height - target_head_height) <= 0.0001
