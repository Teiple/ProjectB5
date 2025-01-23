extends PlayerState
class_name PlayerStateMove

@export var step_up_small_edges := true
@export var upward_speed := 1.0
@export_range(0.0, 3.0, 0.001) var step_up_push_multiplier := 0.7
@export var step_down_small_edges := true
@export_range(0.0, 3.0, 0.001) var step_down_push_multiplier := 0.5
@export var land_height_threshold := 2.0
@export var can_mantle := true
@export_range(0.5, 1.0, 0.001) var mantle_threshold := 0.9
@export var can_grapple := false
# Preventing stepping up and down next to each other
@export var stepping_time_gap := 0.1
# Allow player stands up ;ater if they presssed the crouch button a bit too early
@export var crouch_buffer := 0.2

var move_accel := 20.0
var move_decel := 20.0
var speed := 10.0
var override_move_direction : Vector3
var override_horizontal_velocity : Vector3
var override_vertical_velocity : Vector3
var moving_direction : Vector3
var was_on_floor : bool = false
var crouching : bool = false
var collided_this_physics_frame := false
var last_velocity := Vector3.ZERO
var last_stepping_up_timemark := 0.0
var last_stepping_down_timemark := 0.0

var last_failed_crouch_toggle_timemark := -1.0

func unhandled_input(event):
	if event.is_action_pressed("crouch"):
		crouching = !crouching
		if !crouching:
			# If there is no space to stand up again, the player will keep crouching
			if is_stucked_in_crouching_mode():
				crouching = true
				last_failed_crouch_toggle_timemark = CustomTime.time
			# Else, the player will start standing up
			else:
				player.switch_to_standing_mode()
				last_failed_crouch_toggle_timemark = -1.0
		else:
			player.switch_to_normal_crouching_mode()
		return
	
	if can_grapple && (event.is_action_pressed("fire_1") || event.is_action_pressed("fire_2")):
		player.grapple_raycast.force_raycast_update()
		var grapple_point = Vector3.ZERO
		var action = ""
		if event.is_action_pressed("fire_1"):
			action = "pull"
		else:
			action = "swing"
		var failed = !player.grapple_raycast.is_colliding()
		if !failed:
			grapple_point = player.grapple_raycast.get_collision_point()
		else:
			grapple_point = player.grapple_raycast.to_global(player.grapple_raycast.target_position)
		_state_machine.transition_to("Move/Grapple", {"grapple_point" : grapple_point, "grapple_failed" : failed, "grapple_action" : action})
		return

func get_movement_direction() -> Vector3:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var dir = player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	return dir

func physics_process(delta: float):
	if override_vertical_velocity != Vector3.ZERO:
		player.velocity.y = override_vertical_velocity.y
		override_vertical_velocity = Vector3.ZERO
	# Add gravity
	else:
		player.velocity.y -= player.gravity * delta
	
	# Get the movement direction
	moving_direction = get_movement_direction()
	
	# Override the velocity if specified
	if override_horizontal_velocity != Vector3.ZERO:
		player.velocity.x = override_horizontal_velocity.x
		player.velocity.z = override_horizontal_velocity.z
		override_horizontal_velocity = Vector3.ZERO
	# Apply velocity with smoothing
	elif moving_direction.length_squared() > 0.0001:
		player.velocity.x = lerpf(player.velocity.x, moving_direction.x * speed, 1.0 - pow(0.5, move_accel * delta))
		player.velocity.z = lerpf(player.velocity.z, moving_direction.z * speed, 1.0 - pow(0.5, move_accel * delta))
	else:
		player.velocity.x = lerpf(player.velocity.x, 0.0, 1.0 - pow(0.5, move_decel * delta))
		player.velocity.z = lerpf(player.velocity.z, 0.0, 1.0 - pow(0.5, move_decel * delta))
	
	player.target_horizontal_velocity = Vector3(player.velocity.x, 0.0, player.velocity.z)
	
	was_on_floor = player.is_on_floor()
	last_velocity = player.velocity
	
	player.move_and_slide()
	
	# Check if we've just landed
	if !was_on_floor && player.is_on_floor() && abs(player.velocity.y) < 0.01 && last_velocity.y < 0:
		var fallen_height = player.get_fallen_height_from_velocity(last_velocity.y)
		if fallen_height >= land_height_threshold:
			player.land.emit(fallen_height)
	
	if player.get_slide_collision_count() > 0:
		collided_this_physics_frame = true
	else:
		collided_this_physics_frame = false
	

func process(delta):
	# Crouching (with buffer)
	if CustomTime.time - last_failed_crouch_toggle_timemark <= crouch_buffer && crouching && !is_stucked_in_crouching_mode():
		crouching = false
		player.switch_to_standing_mode()
	
	# Mantling
	# Prevent the player from mantling while grabbing some object
	var grab_component := Component.find_component(player, GrabComponent.get_component_name()) as GrabComponent
	var is_grabbing = grab_component && grab_component.is_grabbing()
	
	if can_mantle && !is_grabbing && Input.is_action_pressed("jump") && try_mantling():
		return
	
	# Jumping
	if Input.is_action_just_pressed("jump") \
	&& _state_machine.get_current_state_path() != "Move/Air" \
	&& !is_stucked_in_crouching_mode():
		_state_machine.transition_to("Move/Air", {"jump" : true})
		return
	
	# Automatically crouching even lower if the enviroment requires it
	var went_under = try_going_under()
	# Handle stepping up/down on low edges
	var stepped_up =  !went_under && step_up_small_edges && try_stepping_up()
	if stepped_up:
		last_stepping_up_timemark = CustomTime.time
	var time_diff = CustomTime.time - last_stepping_up_timemark
	var stepped_down =  time_diff >= stepping_time_gap \
	&& !went_under && !stepped_up \
	&& step_down_small_edges && try_stepping_down()
	if stepped_down:
		last_stepping_down_timemark = CustomTime.time
	
func is_stucked_in_crouching_mode() -> bool:
	if !player.is_crouching():
		return false
	player.crouch_toggle_space_check.shape =  player.get_shrinked_standing_collision_shape()
	player.crouch_toggle_space_check.position = Vector3.ZERO
	player.crouch_toggle_space_check.position.y = player.standing_collision_shape.height * 0.5
	player.crouch_toggle_space_check.target_position = Vector3.ZERO
	
	# Ignore the grabbed object (if there is one)  when the grabbed object is hanging the player head
	var grab_component := Component.find_component(player, GrabComponent.get_component_name()) as GrabComponent
	if grab_component != null:
		if grab_component.current_object != null:
			player.crouch_toggle_space_check.add_exception(grab_component.current_object)
		elif grab_component.last_object != null:
			player.crouch_toggle_space_check.remove_exception(grab_component.last_object)
	player.crouch_toggle_space_check.force_shapecast_update()
	# If there is no space to stand up, the player is stucked in crouching mode
	if player.crouch_toggle_space_check.is_colliding():
		return true
	return false

func try_mantling(automatically : bool = false) -> bool:
	var direction := Vector3.ZERO
	# "Automatically" means that we don't need to
	# control the player to go towards the obstacle
	# to trigger the action
	if automatically:
		direction = -player.global_transform.basis.z
	else:
		# Mantle if the player presses forward
		var dot = (-player.global_basis.z).dot(moving_direction.normalized())
		if dot >= mantle_threshold:
			direction = moving_direction * Vector3(1, 0, 1)
		else:
			return false
	if direction.length_squared() < 0.01:
		return false
	var mantle_position = detect_mantle(direction)
	if mantle_position == null:
		return false
	_state_machine.transition_to("Move/Mantle", {"mantle_position" : mantle_position})
	#player.mantle.emit(mantle_position)
	return true

func try_going_under() -> bool:
	if !player.is_crouching():
		return false
	# Return to normal crouching mode if the enviroment is now more open
	if  player.collision_shape.shape == player.lower_crouching_collision_shape:
		if player.head.is_crouching_toggle_finished():
			player.crouch_toggle_space_check.target_position = Vector3.ZERO
			player.crouch_toggle_space_check.position = Vector3.ZERO
			player.crouch_toggle_space_check.shape = player.crouching_collision_shape
			player.crouch_toggle_space_check.position.y = player.crouching_collision_shape.height * 0.5
			player.crouch_toggle_space_check.force_shapecast_update()
			if !player.crouch_toggle_space_check.is_colliding():
				player.switch_to_normal_crouching_mode()
		return false
	var direction := moving_direction * Vector3(1, 0, 1)
	if direction.length_squared() < 0.01:
		return false
	# We check if the next movement with lower crouching mode will be available,
	player.switch_to_lower_crouching_mode()
	var motion_test := PhysicsTestMotionParameters3D.new()
	motion_test.from = player.global_transform
	var test_distance = 0.1
	motion_test.motion = direction * test_distance
	var result := PhysicsTestMotionResult3D.new()
	var player_rid := player.get_rid()
	PhysicsServer3D.body_test_motion(player_rid, motion_test, result)
	# If it does, then we check if it also available for normal crouching mode as well,
	# If it also does, then we don't need to switch to lower crouching mode,
	player.crouch_toggle_space_check.target_position = Vector3.ZERO
	player.crouch_toggle_space_check.shape = player.get_shrinked_crouching_collision_shape()
	player.crouch_toggle_space_check.global_position = player.global_position + result.get_travel()
	player.crouch_toggle_space_check.global_position.y += player.crouching_collision_shape.height * 0.5
	player.crouch_toggle_space_check.force_shapecast_update()
	if player.crouch_toggle_space_check.is_colliding():
		return true
	player.switch_to_normal_crouching_mode()
	#DebugDraw3D.draw_sphere(player.crouch_toggle_space_check.global_position, player.crouch_toggle_space_check.shape.radius, Color.YELLOW)
	return false

func try_stepping_up() -> bool:
	var direction := moving_direction * Vector3(1, 0, 1)
	if direction.length_squared() < 0.01:
		return false
	# No stepping up while falling
	if player.velocity.y < 0.0:
		return false
	direction = direction.normalized()
	var angle = 20.0
	var collision_point = null
	player.step_offset_raycast_pivot.look_at(player.step_offset_raycast_pivot.global_position + direction * Vector3(1.0, 0.0, 1.0))
	var start_rotation = player.step_offset_raycast_pivot.rotation
	
	if !player.is_crouching():
		player.step_offset_space_check.shape = player.get_shrinked_standing_collision_shape()
	else:
		player.step_offset_space_check.shape = player.get_shrinked_lower_crouching_collision_shape()
	for i in [0, 1, -1, 2, -2, 3, -3]:
		player.step_offset_raycast_pivot.rotation = start_rotation
		player.step_offset_raycast_pivot.rotation.y += deg_to_rad(i * angle)
		player.step_up_raycast.force_raycast_update()
		if player.step_up_raycast.is_colliding():
			var hit_point = player.step_up_raycast.get_collision_point()
			player.step_offset_space_check.global_position = hit_point + Vector3.UP * player.step_offset_space_check.shape.height * 0.5
			player.step_offset_space_check.force_shapecast_update()
			if player.step_offset_space_check.is_colliding():
				#DebugDraw3D.draw_ray(player.step_up_raycast.global_position, Vector3.DOWN, -player.step_up_raycast.target_position.y, Color.RED)
				continue
			collision_point = hit_point
			#DebugDraw3D.draw_ray(player.step_up_raycast.global_position, Vector3.DOWN, -player.step_up_raycast.target_position.y, Color.GREEN)
			break
		#DebugDraw3D.draw_ray(player.step_up_raycast.global_position, Vector3.DOWN, -player.step_up_raycast.target_position.y, Color.RED)
	if collision_point == null:
		return false
	# Motion testing for correct velocity if collided with something,
	# eg. step up stairs near a wall
	var player_rid = player.get_rid()
	var motion_test := PhysicsTestMotionParameters3D.new()
	var motion_length : float = ((player.global_position - collision_point) * Vector3(1, 0, 1)).length()
	var test_motion :=  direction * motion_length
	var xf = player.global_transform
	xf.origin.y = collision_point.y + 0.01
	motion_test.from = xf
	motion_test.motion = test_motion
	var result := PhysicsTestMotionResult3D.new()
	var player_y_velocity = player.velocity.y
	player.velocity = direction * speed
	#player.velocity *= step_up_push_multiplier
	#player.velocity.y = player_y_velocity
	var head_height = player.head.global_position.y
	player.global_position = xf.origin
	player.head.global_position.y = head_height
	# We made the player go to lower crouching mode in case 
	# there is not enough space for normal crouching mode.
	# Useful for getting into the vents
	if player.is_crouching() &&  player.collision_shape.shape != player.lower_crouching_collision_shape:
		player.switch_to_lower_crouching_mode()
	#player.move_and_slide()
	player.step.emit()
	return true

func try_stepping_down() -> bool:
	var direction := player.velocity * Vector3(1, 0, 1)
	if direction.length_squared() < 0.01:
		return false
	direction = direction.normalized()
	if player.is_on_floor() || player.velocity.y >= 0.0:
		return false
	# We don't want to snap to the ground when we land
	# from high enough ground
	if player.get_fallen_height_from_velocity(player.velocity.y) > -player.step_down_raycast.target_position.y:
		return false
	var player_rid = player.get_rid()
	var test_motion := Vector3.DOWN * -player.step_down_raycast.target_position.y
	var motion_test := PhysicsTestMotionParameters3D.new()
	motion_test.from = player.global_transform
	motion_test.motion = test_motion
	var result := PhysicsTestMotionResult3D.new()
	var xf = player.global_transform
	if PhysicsServer3D.body_test_motion(player_rid, motion_test, result):
		# The smaller this number, the smoother the step
		# But it will also cause more steps
		var threshold = 0.1
		if abs(result.get_travel().y) <= threshold:
			return false
		#var collision_point = result.get_collision_point()
		#DebugDraw3D.draw_sphere(collision_point, 0.05, Color.CYAN, 3.0)
		xf.origin.y += result.get_travel().y
		var head_height = player.head.global_position.y
		player.global_transform = xf
		player.head.global_position.y = head_height
		player.velocity.y = -0.2
		player.step.emit()
		return true
	return false

func detect_mantle(direction : Vector3):
	# Very similar to try_step_up(), but instead of moving
	# the player up right away, we'll switch to Mantle state
	# with the additional information about target position
	direction = direction.normalized()
	var angle = 10.0
	var collision_point = null
	player.step_offset_raycast_pivot.look_at(player.step_offset_raycast_pivot.global_position + direction * Vector3(1.0, 0.0, 1.0))
	var start_rotation = player.step_offset_raycast_pivot.rotation
	player.mantle_raycast.position.y = player.head.position.y
	
	player.mantle_raycast.target_position.y = -player.mantle_raycast.position.y - player.step_up_raycast.target_position.y
	# We don't mantle if we could step up instead
	if player.mantle_raycast.target_position.y >= 0:
		player.mantle_raycast.target_position.y = 0.0
		return null
	
	var shapes = []
	if !player.is_crouching():
		shapes.push_back(Player.CollisionShape.STANDING)
	shapes.push_back(Player.CollisionShape.CROUCHING)
	shapes.push_back(Player.CollisionShape.LOWER_CROUCHING)
	
	var chosen_shape : Player.CollisionShape = 0
	for shape in shapes:
		match shape:
			Player.CollisionShape.CROUCHING:
				player.step_offset_space_check.shape = player.get_shrinked_crouching_collision_shape()
			Player.CollisionShape.LOWER_CROUCHING:
				player.step_offset_space_check.shape = player.get_shrinked_lower_crouching_collision_shape()
			Player.CollisionShape.STANDING:
				player.step_offset_space_check.shape = player.get_shrinked_standing_collision_shape()
		chosen_shape = shape
		for i in [0, 1, -1, 2, -2]: #[0, 1, -1, 2, -2, 3, -3]
			player.step_offset_raycast_pivot.rotation = start_rotation
			player.step_offset_raycast_pivot.rotation.y += deg_to_rad(i * angle)
			player.mantle_raycast.force_raycast_update()
			if player.mantle_raycast.is_colliding():
				var hit_point = player.mantle_raycast.get_collision_point()
				player.step_offset_space_check.global_position = hit_point + Vector3.UP * player.step_offset_space_check.shape.height * 0.5
				player.step_offset_space_check.force_shapecast_update()
				if player.step_offset_space_check.is_colliding():
					continue
				collision_point = hit_point
				break
		if collision_point != null:
			break
	
	if collision_point == null:
		return null
	match chosen_shape:
		Player.CollisionShape.CROUCHING:
			player.switch_to_normal_crouching_mode()
		Player.CollisionShape.LOWER_CROUCHING:
			player.switch_to_lower_crouching_mode()
		Player.CollisionShape.STANDING:
			player.switch_to_standing_mode()
	# Return the mantle position as target position for the Move/Mantle state
	return collision_point

func get_current_height_of_space():
	player.height_check_raycast.force_raycast_update()
	if player.height_check_raycast.is_colliding():
		var collision_point = player.height_check_raycast.get_collision_point()
		return collision_point.y - player.global_position
	return player.global_position.y + player.height_check_raycast.target_position.y
