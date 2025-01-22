extends WeaponControllerState

@onready var base_state : WeaponControllerBaseState = get_parent()
var max_duration := 0.0
var state_start_time := 0.0

func unhandled_input(event):
	base_state.unhandled_input(event)

func enter(msg := {}):
	weapon_controller.play_action("holster")
	max_duration = weapon_controller.get_current_anim_length("holster")
	state_start_time = CustomTime.time

func process(delta):
	base_state.process(delta)
	if CustomTime.time - state_start_time > max_duration:
		_state_machine.transition_to("Unarmed")
