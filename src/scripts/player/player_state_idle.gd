extends PlayerState

var base_state : FSMState

func unhandled_input(event):
	base_state.unhandled_input(event)

func physics_process(delta):
	if !player.is_on_floor():
		# Transition: Idle -> Air
		_state_machine.transition_to("Move/Air")
		return
	elif base_state.get_movement_direction().length_squared() > 0.01:
		# Transition: Idle -> Run
		_state_machine.transition_to("Move/Run")
		return
	base_state.physics_process(delta)

func process(delta):
	base_state.process(delta)

func enter(msg := {}):
	base_state = get_parent()
	base_state.speed = 0
