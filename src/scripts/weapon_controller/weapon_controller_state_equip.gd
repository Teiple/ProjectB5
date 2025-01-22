extends WeaponControllerState

@export var min_duration := 0.2
@export var max_duration := 0.0
@onready var base_state : WeaponControllerBaseState = get_parent()
var state_start_time := 0.0

func unhandled_input(event):
	base_state.unhandled_input(event)

func enter(msg := {}):
	weapon_controller.play_action("equip")
	max_duration = weapon_controller.get_current_anim_length("equip")
	state_start_time = CustomTime.time
	weapon_controller.weapon_equipped.emit()

func process(delta):
	var time_passed = CustomTime.time - state_start_time
	if time_passed > max_duration:
		_state_machine.transition_to("Base/Idle")
		return
	base_state.process(delta)
