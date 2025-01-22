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
	weapon_controller.play_action("reload")
	max_duration = weapon_controller.get_current_anim_length("reload")
	state_start_time = CustomTime.time
	reload_mark = weapon_controller.current_weapon.get_reload_mark()
	weapon_reloaded = false

func process(delta):
	var time_passed = CustomTime.time - state_start_time
	if !weapon_reloaded && reload_mark > 0 && time_passed > reload_mark:
		weapon_reloaded = true
		reload()
		weapon_controller.weapon_reloaded.emit()
	if time_passed > max_duration:
		_state_machine.transition_to("Base/Idle")
		return
	base_state.process(delta)

func reload():
	var wpn_name = weapon_controller.current_weapon.weapon_stats.weapon_name
	var reserve_ammo = weapon_controller.get_reserve_ammo_for_current_weapon()
	var clip_size = weapon_controller.current_weapon.weapon_stats.clip_size
	var current_ammo = weapon_controller.current_weapon.current_ammo
	
	var reload_amount = min(reserve_ammo, clip_size - current_ammo) 
	weapon_controller.current_weapon.reload(reload_amount)
	
	weapon_controller.set_reserve_ammo(wpn_name, reserve_ammo - reload_amount)

func can_interrupt(interrupting_state : String) -> bool:
	return weapon_reloaded
