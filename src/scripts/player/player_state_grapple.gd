extends PlayerState

@export var initial_delay := 0.2
@export var overshoot := 1.0
@export var grapple_max_duration := 0.0
@export var y_offset := 0.5
@export var grapple_custom_gravity := 10.0
@export_range(0.0, 1.0, 0.0001) var stopping_drag := 0.8

@onready var base_state : PlayerStateMove = get_parent()

var initial_delay_ended := false
var grapple_point = null
var grapple_failed := false
var state_start_time := 0.0
var launch_velocity := Vector3.ZERO
var rope_length := 0.0
var previous_velocity := Vector3.ZERO

var grapple_action := ""

func unhandled_input(event):
	var time_passed = CustomTime.time - state_start_time
	if time_passed > initial_delay:
		var stop_grappling = false
		if event.is_action_pressed("fire_1") && grapple_action == "pull":
			player.velocity *= stopping_drag
			stop_grappling = true
		if event.is_action_pressed("fire_2") && grapple_action == "swing":
			stop_grappling = true
		if stop_grappling:
			player.grapple_rope.stop_grappling()
			exit_state()
			return

func physics_process(delta):
	var time_passed = CustomTime.time - state_start_time
	if time_passed <= initial_delay:
		# The player can still move around with the previous speed
		base_state.override_horizontal_velocity = previous_velocity * Vector3(1, 0, 1)
		base_state.physics_process(delta)
		return
	elif grapple_failed:
		player.grapple_rope.stop_grappling()
		exit_state()
		return
	elif !initial_delay_ended:
		initial_delay_ended = true
		rope_length = (player.global_position - grapple_point).length()
		if grapple_action == "pull":
			launch_velocity = calculate_launch_velocity(player.global_position, grapple_point, overshoot, -grapple_custom_gravity)
			player.velocity = launch_velocity
			base_state.physics_process(delta)
			return
	
	# Allow some control here
	var control_acceleration = player.in_air_acceleration * base_state.get_movement_direction()
	var velocity = Vector3.ZERO
	if grapple_action == "swing":
		# Stop swinging if we touched the ground
		if player.is_on_floor():
			player.grapple_rope.stop_grappling()
			exit_state()
			return
		# Contrain player's position to rope length
		if (player.global_position - grapple_point).length_squared() < rope_length * rope_length:
			player.global_position = grapple_point + (player.global_position - grapple_point).normalized() * rope_length
		
		var gravity = Vector3.DOWN * grapple_custom_gravity
		var swinging_velocity = calculate_swing_velocity(gravity, player.velocity, player.global_position, grapple_point, delta)
		
		velocity = swinging_velocity
	else:
		# Stop pulling if we touched anything
		if base_state.collided_this_physics_frame:
			player.grapple_rope.stop_grappling()
			# If we can climb up an edge here,
			# transition to Mantle state
			# (automatically done in try_mantling()),
			# Else just transition to Idle state
			#if !base_state.try_mantling(true):
			#	_state_machine.transition_to("Move/Idle")
			exit_state()
			return
		velocity = launch_velocity
		velocity.y = player.velocity.y - grapple_custom_gravity * delta
	
	base_state.override_horizontal_velocity = velocity * Vector3(1, 0, 1) + control_acceleration * delta
	base_state.override_vertical_velocity = velocity * Vector3(0, 1, 0)
	
	base_state.physics_process(delta)

func process(delta):
	var time_passed = CustomTime.time - state_start_time
	if grapple_max_duration > 0.0 && time_passed >= grapple_max_duration:
		player.grapple_rope.stop_grappling()
		exit_state()
		return

func enter(msg := {}):
	base_state = get_parent()
	# We still use the previous state's speed so no speed modification here 
	grapple_point = msg.get("grapple_point", null)
	grapple_failed = msg.get("grapple_failed", true)
	grapple_action = msg.get("grapple_action", "pull")
	var start_position = player.global_position
	player.grapple_rope.start_grappling(grapple_point, initial_delay)
	if grapple_point == null:
		grapple_point = start_position
	state_start_time = CustomTime.time
	initial_delay_ended = false
	previous_velocity = player.velocity

func calculate_swing_velocity(gravity : Vector3, current_velocity : Vector3, current_position : Vector3, swing_point : Vector3, delta : float) -> Vector3:
	var g = gravity
	var p = current_position
	var ar = swing_point
	var d = p - ar
	
	var l = d.length()
	var d_n = d.normalized()
	
	# Apply gravity
	var v_new = current_velocity + g * delta
	# Force the motion into an arc, don't know how it works yet
	v_new = v_new - (v_new.dot(d_n) * d_n)
	
	return v_new

func calculate_launch_velocity(from : Vector3, to : Vector3, overshootYAxis : float, gravity : float)-> Vector3:
	from.y += y_offset
	# h_dir : horizontal direction
	var h_dir := ((to - from) * Vector3(1, 0, 1)).normalized()
	# P_x: horizontal distance to target
	var P_x := ((to - from) * Vector3(1, 0, 1)).length()
	# P_y: relative vertical distance to target
	var P_y := to.y - from.y
	# h: highest point relative to start position vertically
	var h := 0.0
	if P_y < 0:
		h = overshootYAxis
	else:
		h = P_y + overshootYAxis
	# g : gravity
	var g := gravity
	# v_h: velocity on horizontal axis
	var v_h := P_x / (sqrt(-2*h/g) + sqrt(2*(P_y-h)/g))
	# v_v: velocity on vertical axis
	var v_v := sqrt(-2*g*h)
	
	var launch_velocity := v_h * h_dir + Vector3.UP * v_v
	return launch_velocity

func exit_state():
	if !player.is_on_floor():
		_state_machine.transition_to("Move/Air")
		return
	elif base_state.get_movement_direction().length_squared() > 0.01:
		_state_machine.transition_to("Move/Run")
		return
	else:
		_state_machine.transition_to("Move/Idle")
		return
