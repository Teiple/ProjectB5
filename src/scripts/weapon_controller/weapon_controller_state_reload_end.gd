extends WeaponControllerState

@export var min_duration := 0.2
@export var max_duration := 0.0

@onready var base_state : WeaponControllerBaseState = get_parent()

var state_start_time := 0.0
var reload_mark := 0.0
var weapon_reloaded := false

func unhandled_input(event):
	base_state.unhandled_input(event)

func enter(msg := {}):
	weapon_controller.play_action("reload_end", 0.0, false)
	max_duration = weapon_controller.get_current_anim_length("reload_end")
	state_start_time = CustomTime.time
	reload_mark = weapon_controller.current_weapon.get_reload_end_mark()
	weapon_reloaded = false

func process(delta):
	var time_passed = CustomTime.time - state_start_time
	if !weapon_reloaded && reload_mark > 0 && time_passed > reload_mark:
		weapon_reloaded = true
		weapon_controller.current_weapon.reload(1)
		weapon_controller.weapon_reloaded.emit()
	if time_passed > max_duration:
		_state_machine.transition_to("Base/Idle")
		return
	base_state.process(delta)

func can_interrupt(interrupting_state : String) -> bool:
	return weapon_reloaded
