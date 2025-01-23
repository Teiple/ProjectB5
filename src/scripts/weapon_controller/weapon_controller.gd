extends Node3D
class_name WeaponController

signal weapon_fired
signal weapon_equipped
signal weapon_changed
signal weapon_reloaded
signal weapon_meleed

@export var arms_anim_player : AnimationPlayer = null
@export var arms_mesh : MeshInstance3D = null
@export var arms_animation_pattern := "arms_%weapon_%action"
@export var arms_view_mat : Material = null
@export var reserve_ammo := {}
@export var arms_reset_anim := "arms_t_pose"
@export var auto_reloading := true 

@onready var weapons : Node3D = %Weapons
@onready var player : Player = owner
@onready var state_machine : StateMachine = $StateMachine

var current_weapon : Weapon = null
var last_weapon : Weapon = null

func _ready():
	arms_mesh.material_override = arms_view_mat
	if !player.is_node_ready():
		await player.ready
	player.mantle_started.connect(on_player_mantle_started)
	player.mantle_finished.connect(on_player_mantle_finished)

func on_player_mantle_started(mantle_position : Vector3):
	if has_any_weapons():
		state_machine.transition_to("Base/Holster")

func on_player_mantle_finished():
	if has_any_weapons():
		state_machine.transition_to("Base/Equip")

func get_current_weapon_name() -> String:
	if !has_any_weapons():
		return ""
	return current_weapon.weapon_stats.weapon_name

# If 'queue_default_anim' is true, resets to the default "idle" animation after the current action is finished. 
# Useful for cleaning up leftover states, but can be set to false for continuous animations like multi-part reloads.
func play_action(action : String, offset : float = 0.0, queue_default_anim : bool = false):
	if action == arms_reset_anim:
		arms_anim_player.stop(true)
		arms_anim_player.play(arms_reset_anim)
		return
	if !has_any_weapons():
		return
	var anim = get_arms_anim_name(action)
	var default_anim = get_arms_anim_name("idle")
	arms_anim_player.stop(true)
	var speed_multiplier = current_weapon.weapon_stats.get_speed_multiplier(action)
	current_weapon.play_action(action, queue_default_anim, speed_multiplier)
	arms_anim_player.play(anim, -1, speed_multiplier)
	if arms_anim_player.has_animation(anim):
		arms_anim_player.play(anim, -1, speed_multiplier)
		if queue_default_anim:
			arms_anim_player.queue(default_anim)
	else:
		arms_anim_player.play(anim, -1, speed_multiplier)

func get_current_anim_length(action : String) -> float:
	var speed_multiplier = current_weapon.weapon_stats.get_speed_multiplier(action)
	return arms_anim_player.current_animation_length / speed_multiplier

func get_arms_anim_name(action : String) -> String:
	var anim = arms_animation_pattern.replace("%weapon", get_current_weapon_name())
	anim = anim.replace("%action", action)
	return anim

func change_weapon(new_weapon : Weapon):
	if !has_any_weapons():
		return
	current_weapon = new_weapon
	for wpn : Weapon in weapons.get_children():
		var is_chosen = wpn == current_weapon
		wpn.visible = is_chosen
		wpn.set_material_for_view(is_chosen)
		if is_chosen && wpn.state_machine.get_current_state_path() != "UsedByPlayer/Selected":
			wpn.state_machine.transition_to("UsedByPlayer/Selected")
		if !is_chosen && wpn.state_machine.get_current_state_path() != "UsedByPlayer/Unselected":
			wpn.state_machine.transition_to("UsedByPlayer/Unselected")

func get_next_weapon_in_hierachy() -> Weapon:
	return scroll_weapon(true)

func get_previous_weapon_in_hierachy() -> Weapon:
	return scroll_weapon(false)

func scroll_weapon(next : bool = false) -> Weapon:
	if !has_any_weapons():
		return null
	var wpn = current_weapon
	if weapons.get_child_count() == 0 || wpn.get_parent() != weapons:
		return null
	var wpn_idx = wpn.get_index()
	wpn_idx += 1 if next else -1
	if wpn_idx > weapons.get_child_count() - 1:
		wpn_idx = 0
	if wpn_idx < 0:
		wpn_idx = weapons.get_child_count() - 1
	return weapons.get_child(wpn_idx) as Weapon

func set_reserve_ammo(weapon_name : String, ammo : int):
	if reserve_ammo.has(weapon_name):
		reserve_ammo[weapon_name] = ammo

func get_reserve_ammo(weapon_name : String) -> int:
	return reserve_ammo.get(weapon_name, 0)

func get_reserve_ammo_for_current_weapon() -> int:
	if !is_holding_weapon():
		return 0
	return reserve_ammo.get(current_weapon.weapon_stats.weapon_name, 0)

func has_any_weapons() -> bool:
	return weapons.get_child_count() > 0

func is_holding_weapon() -> bool:
	return is_instance_valid(current_weapon) && current_weapon in weapons.get_children()

func take_weapon(weapon : Weapon):
	# If we already had this kind of weapon,
	# only take its ammo
	for wpn in weapons.get_children():
		if weapon.weapon_stats.weapon_name == wpn.weapon_stats.weapon_name:
			# Take its ammo
			if reserve_ammo.has(weapon.weapon_stats.weapon_name):
				reserve_ammo[weapon.weapon_stats.weapon_name] += weapon.take_available_ammo()
			return
	# Add new weapon
	if !reserve_ammo.has(weapon.weapon_stats.weapon_name):
		reserve_ammo[weapon.weapon_stats.weapon_name] = 0
	weapon.get_parent().remove_child(weapon)
	weapons.add_child(weapon)
	# Equip new weapon
	change_weapon(weapon)
	state_machine.transition_to("Base/Equip")

func take(object : Node3D):
	var grab_component := Component.find_component(player, GrabComponent.get_component_name()) as GrabComponent
	# Don't pick up things if our hands are busy
	if (grab_component && grab_component.is_grabbing()):
		return
	if object is Weapon:
		take_weapon(object)
