extends WeaponControllerState
class_name WeaponControllerBaseState

# The minimum duration between two scrolling events to prevent rapid weapon changes
@export var weapon_switching_cool_down := 0.1

var last_weapon_switching_time := 0.0

func unhandled_input(event):
	if !weapon_controller.is_holding_weapon():
		return
	if weapon_controller.player.state_machine.is_in_one_of_states(["Move/Mantle"]):
		return
	
	if CustomTime.time - last_weapon_switching_time >= weapon_switching_cool_down:
		if event.is_action_pressed("weapon_scroll_up"):
			var new_wpn = weapon_controller.get_next_weapon_in_hierachy()
			change_current_weapon(new_wpn)
			last_weapon_switching_time = CustomTime.time
			return
		elif event.is_action_pressed("weapon_scroll_down"):
			var new_wpn = weapon_controller.get_previous_weapon_in_hierachy()
			change_current_weapon(new_wpn)
			last_weapon_switching_time = CustomTime.time
			return
	# Changing weapons by pressing number keys
	for i in 10:
		if i >= weapon_controller.weapons.get_child_count():
			break
		var action_name := "number_" + str(i+1)
		if InputMap.has_action(action_name) && event.is_action_pressed(action_name):
			var wpn = weapon_controller.weapons.get_child(i)
			change_current_weapon(wpn as Weapon)
			last_weapon_switching_time = CustomTime.time
			return

func change_current_weapon(new_weapon : Weapon):
	if !weapon_controller.is_holding_weapon():
		return false
	if weapon_controller.current_weapon == new_weapon:
		return
	weapon_controller.change_weapon(new_weapon)
	_state_machine.transition_to("Base/Equip")
	weapon_controller.weapon_changed.emit()

func process(delta):
	if !weapon_controller.is_holding_weapon():
		return
	if weapon_controller.player.state_machine.is_in_one_of_states(["Move/Mantle"]):
		return
	if Input.is_action_just_pressed("reload"):
		handle_reloading()
	elif Input.is_action_pressed("fire_1"):
		handle_firing()
	elif Input.is_action_just_pressed("melee"):
		if !_state_machine.is_in_one_of_states(["Base/Equip", "Base/Holster", "Base/Melee"]):
			_state_machine.transition_to("Base/Melee")
			return

func can_fire_now() -> bool:
	if !weapon_controller.is_holding_weapon():
		return false
	if Input.is_action_just_pressed("fire_1"):
		if weapon_controller.current_weapon.can_weapon_rapid_fire():
			return true
	elif Input.is_action_pressed("fire_1") && weapon_controller.current_weapon.can_weapon_fire():
		return true
	return false

func handle_reloading() -> bool:
	if !_state_machine.is_in_one_of_states(["Base/Equip", "Base/Reload*", "Base/Melee"], true)  && weapon_controller.get_reserve_ammo_for_current_weapon() > 0 && weapon_controller.current_weapon.can_weapon_reload():
		if weapon_controller.current_weapon.weapon_stats.shotgun_reload:
			_state_machine.transition_to("Base/ReloadStart")
		else:
			_state_machine.transition_to("Base/Reload")
		return true
	return false

func handle_firing() -> bool:
	if !_state_machine.is_in_one_of_states(["Base/Equip", "Base/Fire"]):
		var current_state_path := _state_machine.get_current_state_path()
		var current_state := _state_machine.state as WeaponControllerState
		# Auto reload if trying to fire without ammo
		if is_weapon_empty_and_can_auto_reload() && !current_state_path.match("Base/Reload*"):
			handle_reloading()
			return true
		# Fire immediately if the reload animation has passed the reload time
		if current_state_path.match("Base/Reload*"):
			if current_state.can_interrupt("Base/Fire") && weapon_controller.current_weapon.can_weapon_fire():
				_state_machine.transition_to("Base/Fire")
				return true
		else:
			if weapon_controller.current_weapon.can_weapon_fire():
				_state_machine.transition_to("Base/Fire")
				return true
	return false

func is_weapon_empty_and_can_auto_reload() -> bool:
	return weapon_controller.auto_reloading && weapon_controller.current_weapon.current_ammo <= 0
