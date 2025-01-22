extends WeaponControllerState

@export var min_duration := 0.2
@export var max_duration := 0.0
@onready var base_state : WeaponControllerBaseState = get_parent()
var state_start_time := 0.0

func unhandled_input(event):
	base_state.unhandled_input(event)

func enter(msg := {}):
	fire()

func process(delta):
	var time_passed = CustomTime.time - state_start_time
	if time_passed > max_duration:
		_state_machine.transition_to("Base/Idle")
		return
	if base_state.can_fire_now():
		fire()
	base_state.process(delta)

func fire():
	weapon_controller.play_action("fire")
	max_duration = weapon_controller.get_current_anim_length("fire")
	state_start_time = CustomTime.time
	weapon_controller.weapon_fired.emit()
	
	# Auto reload if the weapon becomes empty after this shot
	var reloading_started = false
	if base_state.is_weapon_empty_and_can_auto_reload():
		reloading_started = base_state.handle_reloading()
