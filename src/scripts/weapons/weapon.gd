@tool
extends RigidBody3D
class_name Weapon

signal fire_requested()
signal melee_requested

@export var current_ammo := 0
@export var weapon_stats : WeaponStats = null
@export var weapon_view_mat : Material
@export_group("Collision")
@export_flags_3d_physics var dropped_collision_layer := 1
@export_flags_3d_physics var dropped_collision_mask := 1
@export_group("Animations")
@export var weapon_anim_name_pattern := "wpn_%weapon_%action"
## Used by the weapon controller to reload weapon at
## a specific time in the reload animation 
@export var unscaled_reload_mark := 0.0
@export var unscaled_reload_start_mark := -1.0
@export var unscaled_reload_mid_mark := -1.0
@export var unscaled_reload_end_mark := -1.0
@export var unscaled_melee_mark := -1.0

@export_group("Editor Tools")
@export var set_current_transform_as_relative_transform := false :
	set(val):
		if Engine.is_editor_hint():
			set_relative_transform()
@export var apply_saved_relative_transform := false :
	set(val):
		if Engine.is_editor_hint():
			apply_relative_transform()
@export var set_current_animation_timemarks := false :
	set(val):
		if Engine.is_editor_hint():
			set_animation_timemarks()
@export var apply_saved_animation_timemarks := false :
	set(val):
		if Engine.is_editor_hint():
			apply_animation_timemarks()
@export_group("", "")

@onready var weapon_mesh : MeshInstance3D = _get_weapon_mesh()
@onready var anim_player : AnimationPlayer = get_child(0).get_node("AnimationPlayer")
@onready var pickup_zone : Zone = $PickupZone
@onready var state_machine : StateMachine = $WeaponStateMachine

var last_firing_time := 0.0

func _ready():
	if Engine.is_editor_hint():
		return
	pickup_zone.zone_entered.connect(_on_pickup_zone_zone_entered)

func get_weapon_stats() -> WeaponStats:
	return weapon_stats

func take_available_ammo() -> int:
	var ammo = current_ammo
	current_ammo = 0
	return ammo

func set_animation_timemarks():
	weapon_stats.unscaled_reload_mark = unscaled_reload_mark
	weapon_stats.unscaled_reload_start_mark = unscaled_reload_start_mark
	weapon_stats.unscaled_reload_mid_mark = unscaled_reload_mid_mark
	weapon_stats.unscaled_reload_end_mark = unscaled_reload_end_mark
	weapon_stats.unscaled_melee_mark = unscaled_melee_mark
	if Engine.is_editor_hint():
		print_debug("Saved animation timemarks")

func apply_animation_timemarks():
	unscaled_reload_mark = weapon_stats.unscaled_reload_mark
	unscaled_reload_start_mark = weapon_stats.unscaled_reload_start_mark
	unscaled_reload_mid_mark = weapon_stats.unscaled_reload_mid_mark
	unscaled_reload_end_mark = weapon_stats.unscaled_reload_end_mark
	unscaled_melee_mark = weapon_stats.unscaled_melee_mark
	if Engine.is_editor_hint():
		print_debug("Applied animation timemarks")

func set_relative_transform():
	weapon_stats.relative_position = position
	weapon_stats.relative_rotation = rotation_degrees
	if Engine.is_editor_hint():
		print_debug("Saved relative transform")

func apply_relative_transform():
	position = weapon_stats.relative_position
	rotation_degrees = weapon_stats.relative_rotation
	if Engine.is_editor_hint():
		print_debug("Applied relative transform")

func can_weapon_fire() -> bool:
	if current_ammo > 0 && CustomTime.time - last_firing_time >= weapon_stats.fire_rate:
		return true
	return false

func can_weapon_rapid_fire() -> bool:
	if weapon_stats.rapid_fire && current_ammo > 0:
		return true
	return false

func can_weapon_reload() -> bool:
	if current_ammo < weapon_stats.clip_size:
		return true
	return false

func fire():
	last_firing_time = CustomTime.time
	current_ammo -= 1
	fire_requested.emit()

func melee():
	melee_requested.emit()

func play_action(action : String, queue_default_anim : bool = true, speed_multiplier : = 1.0):
	var anim = get_weapon_anim_name(action)
	var default_anim = get_weapon_anim_name("idle")
	anim_player.stop(true)
	if anim_player.has_animation(anim):
		anim_player.play(anim, -1, speed_multiplier)
		if queue_default_anim:
			anim_player.queue(default_anim)
	else:
		anim_player.play(default_anim, -1, speed_multiplier)
	if action == "fire":
		fire()

func get_weapon_anim_name(action : String) -> String:
	var anim = weapon_anim_name_pattern.replace("%weapon", weapon_stats.weapon_name)
	anim = anim.replace("%action", action)
	return anim

func set_material_for_view(is_in_view : bool):
	if is_in_view:
		weapon_mesh.material_override = weapon_view_mat
	else:
		weapon_mesh.material_override = null

func reload(amount : int):
	current_ammo += amount

func get_reload_mark() -> float:
	return weapon_stats.unscaled_reload_mark / weapon_stats.reload_speed_multiplier

func get_reload_start_mark() -> float:
	return weapon_stats.unscaled_reload_start_mark / weapon_stats.reload_speed_multiplier

func get_reload_mid_mark() -> float:
	return weapon_stats.unscaled_reload_mid_mark / weapon_stats.reload_speed_multiplier

func get_reload_end_mark() -> float:
	return weapon_stats.unscaled_reload_end_mark / weapon_stats.reload_speed_multiplier

func get_melee_mark() -> float:
	return weapon_stats.unscaled_melee_mark / weapon_stats.melee_speed_multiplier
	
func _on_pickup_zone_zone_entered(who : Node3D):
	if who is Player:
		var player = who as Player
		player.weapon_controller.take(self)

func shader_cache_fetch_material_meshes(material_property : String) -> Array[MeshInstance3D]:
	match material_property:
		"weapon_view_mat":
			var weapon_mesh = _get_weapon_mesh()
			return [weapon_mesh]
		_:
			return []

func _get_weapon_mesh() -> MeshInstance3D: 
	return get_child(0).get_child(0).get_child(0).get_child(0) as MeshInstance3D

	
