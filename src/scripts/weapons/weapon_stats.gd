extends Resource
class_name WeaponStats

@export var weapon_name := ""
@export_range(0.0, 100.0, 1, "or_greater") var damage_per_projectile := 1.0
@export_range(0.0, 100.0, 1, "or_greater") var knock_back_force_per_projectile := 1.0
@export_range(0, 10, 1, "or_greater") var projectiles_per_shot := 1
@export_range(0, 10, 1, "or_greater") var clip_size := 10
@export_range(0.0, 90.0, 0.001, "radians_as_degrees") var max_angle := 0.00872665
@export_range(0.0, 1.0, 0.001, "or_greater") var fire_rate := 0.2
## Notice that hitscan weapons require the present of "WeaponRaycastComponent",
## while projectile weapons require "WeaponProjectileComponent".
## If you wanted to change this property in-game, you need both components to be the 
## children of each target weapon 
@export var hitscan : bool = true
@export var projectile_speed := 40.0

@export_group("Reload")
@export var shotgun_reload := false
## If shotgun_reload is set to true, this value indicates how many rounds will be loaded at a time
@export var shotgun_reload_amount := 1 
@export_group("Transform")
@export var relative_position := Vector3.ZERO
@export var relative_rotation := Vector3.ZERO
@export_group("Animations")
@export var rapid_fire := false
@export_range(0.0, 3.0, 0.001, "or_greater") var equip_speed_multiplier := 1.0
@export_range(0.0, 3.0, 0.001, "or_greater") var fire_speed_multiplier := 1.0
@export_range(0.0, 3.0, 0.001, "or_greater") var reload_speed_multiplier := 1.0
@export_range(0.0, 3.0, 0.001, "or_greater") var melee_speed_multiplier := 1.0
@export_range(0.0, 3.0, 0.001, "or_greater") var holster_speed_multiplier := 1.0
@export var unscaled_reload_mark := 0.0
@export var unscaled_reload_start_mark := -1.0
@export var unscaled_reload_mid_mark := -1.0
@export var unscaled_reload_end_mark := -1.0
@export var unscaled_melee_mark := -1.0


func get_speed_multiplier(action : String) -> float:
	match action:
		"equip":
			return equip_speed_multiplier
		"fire":
			return fire_speed_multiplier
		"reload", "reaload_start", "reload_mid", "reload_end":
			return reload_speed_multiplier
		"melee":
			return melee_speed_multiplier
		"holster":
			return holster_speed_multiplier
	return 1.0
