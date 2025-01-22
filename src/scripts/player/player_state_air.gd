extends PlayerState

@export_range(0.0, 1.0, 0.001) var velocity_preservation : float = 0.9
@export var drag := 1.0

var base_state : FSMState
var timer := 0.0
var physics_timer := 0.0
var coyote_jumped := false
var jump_buffered_timemark := 0.0
var jump_intented := false
const MIN = -10000.0

func unhandled_input(event):
	base_state.unhandled_input(event)
	if event.is_action_pressed("jump"):
		# Jump intented means that the player wanted to jump when entering this state,
		# We need to disable coyote time when player wanted to jump so they won't make
		# a double jump in mid air, in case the jump duration was too short (<= coyote time)
		if !coyote_jumped && !jump_intented && timer <= player.coyote_time && player.velocity.y < 0:
			jump()
			coyote_jumped = true
		jump_buffered_timemark = timer

func physics_process(delta):
	# We need to check if we have gone through at least one physics frame,
	# because player.move_and_slide() will not be called until the first 
	# physics frame. It would still make sense for player.is_on_floor() to
	# return true in the first frame even though we jumped
	if player.is_on_floor() && physics_timer > 0.0:
		# Implement jump buffer
		if (timer - jump_buffered_timemark) <= player.jump_buffer_time:
			jump()
			base_state.physics_process(delta)
			physics_timer += delta
			return
		if base_state.get_movement_direction().length_squared() > 0.01:
			# Transition: Air -> Run
			_state_machine.transition_to("Move/Run")
			return
		else:
			# Transition: Air -> Idle
			_state_machine.transition_to("Move/Idle")
			return
	var horizontal_velocity = player.velocity * Vector3(1, 0, 1)
	var control_accel = base_state.get_movement_direction() * player.in_air_acceleration
	horizontal_velocity += control_accel * delta
	base_state.override_horizontal_velocity = horizontal_velocity * clampf(1.0 - drag * delta, 0.0, 1.0)
	base_state.physics_process(delta)
	physics_timer += delta
	
func process(delta): 
	base_state.process(delta)
	timer += delta

func enter(msg := {}):
	base_state = get_parent()
	if msg.has("jump"):
		jump_intented = true
		jump()
	else:
		jump_intented = false
	base_state.speed = player.move_speed
	# Reduce the velocity abit, so
	# the player's speed in air won't be
	# significantly faster than running
	# player.velocity *= Vector3.UP + Vector3(1, 0, 1) * velocity_preservation
	timer = 0.0
	physics_timer = 0.0
	coyote_jumped = false
	jump_buffered_timemark = MIN

func jump():
	player.velocity.y = player.get_jump_speed()
	player.jump.emit()
