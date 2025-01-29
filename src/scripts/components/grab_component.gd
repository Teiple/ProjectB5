extends Component
class_name GrabComponent

signal grabbed(obj : PhysicsObject)
signal released(obj : PhysicsObject)

@export var grab_distance := 1.2
@export var accel_to_grab_point := 40.0
@export var angular_accel_to_grab_point := 30.0
@export var raycast_length := 2.0
@export var throw_speed := 4.0
@export var break_distance := 2.0
@export var release_speed_multiplier := 0.5
@export var release_max_speed := 5.0
#@export var grab_smooth_speed := 30.0
@export_flags_3d_physics var grabbed_collision_layer := 0
@export_flags_3d_physics var grabbed_collision_mask := 0

@onready var player : Player = owner
@onready var raycast: RayCast3D = $GrabRaycast
@onready var obstacle_raycast: RayCast3D = $ObstacleRaycast

var push_component : PushComponent = null

var current_object : PhysicsObject = null
var last_object : PhysicsObject = null
var release_velocity : Vector3 = Vector3.ZERO
var current_object_initial_collision_layer : int = 0
var current_object_initial_collision_mask : int = 0
var drag_velocity := Vector3.ZERO

var last_grab_point := Vector3.ZERO

static func get_component_name()-> String:
	return "GrabComponent"

func _ready() -> void:
	super._ready()
	# All the accel should never greater than physics framerate
	var physics_frame_rate = Engine.physics_ticks_per_second
	accel_to_grab_point = clampf(accel_to_grab_point, 0.0, physics_frame_rate)
	angular_accel_to_grab_point = clampf(angular_accel_to_grab_point, 0.0, physics_frame_rate)
	if !player.is_node_ready():
		await player.ready
	push_component = Component.find_component(player, PushComponent.get_component_name()) as PushComponent
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if current_object != null:
			release_object()
		else:
			raycast.global_position = player.head.global_position
			raycast.look_at(raycast.global_position - player.head.global_basis.z)
			raycast.target_position = Vector3.FORWARD * raycast_length
			raycast.force_raycast_update()
			
			var damageable := raycast.get_collider() as PhysicsObject
			if damageable != null:
				grab_object(damageable)
	if event.is_action_pressed("fire_1"):
		if current_object != null:
			release_object(-player.head.global_basis.z * throw_speed)

func _process(delta: float) -> void:
	# Move fire_2 checks in here since Weapon Controller also checks for input in _process loop
	# Move this into _unhanheld_input will cause double input
	if Input.is_action_just_pressed("fire_2"):
		if current_object != null:
			release_object()

func grab_object(obj : PhysicsObject):
	obj.gravity_scale = 0.0
	obj.linear_velocity = Vector3.ZERO
	obj.angular_velocity = Vector3.ZERO
	current_object = obj
	
	current_object_initial_collision_layer = current_object.collision_layer
	current_object_initial_collision_mask = current_object.collision_mask
	current_object.collision_layer = grabbed_collision_layer
	current_object.collision_mask = grabbed_collision_mask
	current_object.scrape_sfx = false
	#var interpolation_component := Component.find_component(current_object, MeshInterpolationComponent.get_component_name()) as MeshInterpolationComponent
	#if interpolation_component != null:
		#interpolation_component.enabled = true
	
	last_grab_point = get_grab_point()
	grabbed.emit(current_object)
	
	if player.weapon_controller.has_any_weapons():
		player.weapon_controller.state_machine.transition_to("Base/Holster")
	
	player.head.change_update_time(PlayerHead.UpdateTime.PHYSICS_FRAME)
	
func release_object(release_velocity : Vector3 = Vector3.ZERO):
	current_object.gravity_scale = 1.0
	current_object.linear_velocity = Vector3.ZERO
	current_object.angular_velocity = Vector3.ZERO
	
	current_object.collision_layer = current_object_initial_collision_layer
	current_object.collision_mask = current_object_initial_collision_mask
	current_object.scrape_sfx = true
	
	
	release_velocity += drag_velocity * release_speed_multiplier
	
	if release_velocity.length_squared() > release_max_speed * release_max_speed:
		release_velocity = release_velocity.normalized() * release_max_speed
	current_object.apply_central_impulse(release_velocity)

	#var interpolation_component := Component.find_component(current_object, MeshInterpolationComponent.get_component_name()) as MeshInterpolationComponent
	#if interpolation_component != null:
		#interpolation_component.enabled = false
	
	released.emit(current_object)
	last_object = current_object
	current_object = null
	
	if player.weapon_controller.has_any_weapons():
		player.weapon_controller.state_machine.transition_to("Base/Equip")
	
	player.head.change_update_time(PlayerHead.UpdateTime.DEFAULT)

func _physics_process(delta: float) -> void:
	if current_object == null:
		return
	
	var grab_point = get_grab_point() #lerp(last_grab_point, get_grab_point(), grab_smooth_speed * delta)
	drag_velocity = (grab_point - last_grab_point) / delta
	last_grab_point = grab_point
	
	# Break condition
	# Out of range
	var distance_squared = current_object.global_position.distance_squared_to(grab_point)
	if distance_squared >= break_distance * break_distance:
		release_object()
		return
	# Obstacle inbetween
	obstacle_raycast.global_position = current_object.global_position
	obstacle_raycast.target_position = obstacle_raycast.to_local(player.head.global_position)
	obstacle_raycast.force_raycast_update()
	if obstacle_raycast.is_colliding():
		release_object()
		return
	# Being standed on
	if push_component != null && push_component.is_standing_on(current_object):
		release_object()
		return
	# Hold in a too wide angle
	var grab_direction = (grab_point - player.head.global_position).normalized()
	var hold_direction = (current_object.global_position - player.head.global_position).normalized()
	if grab_direction.dot(hold_direction) < 0.5:
		release_object() 
		return
	
	var arc_to = -grab_direction
	var arc_from = get_nearest_grab_direction(current_object, arc_to)["global"]
	
	var up_arc_to = player.head.global_basis.y
	var up_arc_from = get_nearest_grab_direction(current_object, up_arc_to)["global"]
	var up_axis_quat = Quaternion(up_arc_from, up_arc_to) if (up_arc_to != arc_to) else Quaternion.IDENTITY
	
	current_object.angular_velocity = (up_axis_quat * Quaternion(arc_from, arc_to)).get_euler() * angular_accel_to_grab_point
	# Try not push this object into player, it will move the player on collision, which is not desirable
	var test_motion = PhysicsTestMotionParameters3D.new()
	test_motion.from = current_object.global_transform
	test_motion.motion = (grab_point - current_object.global_position) * accel_to_grab_point * delta
	var test_motion_result = PhysicsTestMotionResult3D.new()
	var would_collide_with_player = false
	if PhysicsServer3D.body_test_motion(current_object.get_rid(), test_motion, test_motion_result):
		for i in test_motion_result.get_collision_count():
			if test_motion_result.get_collider() is Player:
				would_collide_with_player = true
	# Translation
	if distance_squared > 0.0001 && !would_collide_with_player:
		var aim_translation = grab_point - current_object.global_position
		current_object.linear_velocity = aim_translation / delta
	else:
		current_object.linear_velocity = Vector3.ZERO

func get_nearest_grab_direction(obj : PhysicsObject, grab_direction : Vector3):
	var global_directions = {
		Vector3.FORWARD : -obj.global_basis.z,
		Vector3.BACK : obj.global_basis.z,
		Vector3.UP : obj.global_basis.y,
		Vector3.DOWN : -obj.global_basis.y,
		Vector3.LEFT : -obj.global_basis.x,
		Vector3.RIGHT : obj.global_basis.x,
	}
	var nearest_local_direction = Vector3.FORWARD
	var largest_dot = -1
	for dir_v in global_directions:
		var dot = grab_direction.dot(global_directions[dir_v])
		if dot > largest_dot:
			largest_dot = dot
			nearest_local_direction = dir_v
	return {"local" : nearest_local_direction, "global" : global_directions[nearest_local_direction]}

func get_grab_point():
	return player.head.global_position - player.head.global_basis.z * grab_distance

func is_grabbing() -> bool:
	return current_object != null
