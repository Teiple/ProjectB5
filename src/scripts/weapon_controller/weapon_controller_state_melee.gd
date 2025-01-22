extends WeaponControllerState

@export var min_duration := 0.2
@export var max_duration := 0.0

@onready var base_state : WeaponControllerBaseState = get_parent()

var state_start_time := 0.0
var melee_mark := 0.0
var meleed := false

func unhandled_input(event):
	base_state.unhandled_input(event)

func enter(msg := {}):
	weapon_controller.play_action("melee")
	max_duration = weapon_controller.get_current_anim_length("melee")
	state_start_time = CustomTime.time
	meleed = false
	melee_mark = weapon_controller.current_weapon.get_melee_mark()

func process(delta):
	var time_passed = CustomTime.time - state_start_time
	if !meleed && melee_mark > 0.0 && time_passed > melee_mark:
		meleed = true
		melee()
		weapon_controller.weapon_meleed.emit()
	if time_passed > max_duration:
		_state_machine.transition_to("Base/Idle")
		return
	base_state.process(delta)

func melee():
	weapon_controller.current_weapon.melee()
