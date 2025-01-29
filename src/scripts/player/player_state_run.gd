extends PlayerState

@onready var base_state : PlayerStateMove = get_parent()

func unhandled_input(event):
	base_state.unhandled_input(event)

func physics_process(delta):
	if player.is_crouching():
		base_state.speed = player.move_speed * (1.0 - player.crouch_speed_reduction)
	else:
		if (Input.is_action_pressed("sprint")):
			base_state.speed = player.move_speed * player.sprint_speed_multiplier
		else:
			base_state.speed = player.move_speed
	
	if !player.is_on_floor():
		# Transition: Run -> Air
		_state_machine.transition_to("Move/Air")
		return
	elif base_state.get_movement_direction().length_squared() <= 0.01:
		# Transition: Run -> Idle
		_state_machine.transition_to("Move/Idle")
		return
	base_state.physics_process(delta)

func process(delta):
	base_state.process(delta)

func enter(msg := {}):
	base_state = get_parent()
