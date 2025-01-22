extends Component
class_name WeaponProjectileComponent

@export var starting_point_transform : Node3D = null
@export var forward_shooting_direction_transform : Node3D = null

@onready var weapon : Weapon = owner
@onready var raycast : RayCast3D = $RayCast3D

var max_distance := 100.0
var shooting_angle := Vector2.ZERO

func _ready() -> void:
	if !weapon.is_node_ready():
		await weapon.ready
	weapon.fire_requested.connect(_on_fire_requested)

static func get_component_name() -> String:
	return "WeaponProjectileComponent"

func _on_fire_requested():
	# Only apply if the weapon uses projectiles
	if weapon.weapon_stats.hitscan:
		return
	for i in weapon.weapon_stats.projectiles_per_shot:
		shoot_one_shot()

func _aim_raycast():
	var user_is_player = weapon.state_machine.get_current_state_path() == "UsedByPlayer/Selected"
	# if not, user is an npc
	if user_is_player:
		add_exceptions_for_user(Global.current_game().player())
	
	var start_pnt = aim_starting_point()
	var shoot_dir = aim_shooting_direction()
	
	raycast.global_position = start_pnt
	raycast.target_position = Vector3(0.0, 0.0, -max_distance)
	raycast.look_at(start_pnt + shoot_dir)
	
	shooting_angle = Vector2(randf_range(-weapon.weapon_stats.max_angle, weapon.weapon_stats.max_angle), randf_range(-weapon.weapon_stats.max_angle, weapon.weapon_stats.max_angle))
	
	raycast.rotate_x(shooting_angle.x)
	raycast.rotate_y(shooting_angle.y)
	
	#raycast.force_raycast_update()

func shoot_one_shot():
	_aim_raycast()
	
	var start_position = projectile_starting_point()
	var fly_direcion = -raycast.global_basis.z
	
	var projectile_pool := Global.current_game().get_node_or_null(ProjectilePool.get_pool_name()) as ProjectilePool
	var set_up_info := {
		"start_position" : start_position,
		"fly_direction" : fly_direcion,
		"weapon_stats" : weapon.weapon_stats,
		"projectile_speed" : weapon.weapon_stats.projectile_speed
		# future: attacker
	}
	# Create projectile
	projectile_pool.get_pooled_item(set_up_info)

func projectile_starting_point() -> Vector3:
	var use_player_camera_for_starting_point = weapon.state_machine.get_current_state_path() == "UsedByPlayer/Selected"
	
	if starting_point_transform != null:
		return starting_point_transform.global_position
	return Vector3.ZERO

func aim_starting_point() -> Vector3:
	var use_player_camera_for_starting_point = weapon.state_machine.get_current_state_path() == "UsedByPlayer/Selected"
	
	if use_player_camera_for_starting_point:
		return Global.current_game().player().camera.global_position
	if starting_point_transform != null:
		return starting_point_transform.global_position
	return Vector3.ZERO

func aim_shooting_direction() -> Vector3:
	var use_player_camera_for_shooting_direction = weapon.state_machine.get_current_state_path() == "UsedByPlayer/Selected"
	
	if use_player_camera_for_shooting_direction:
		return -Global.current_game().player().camera.global_basis.z
	if forward_shooting_direction_transform != null:
		return -forward_shooting_direction_transform.global_basis.z
	return Vector3.ZERO

func add_exceptions_for_user(user : Node3D):
	raycast.clear_exceptions()
	var hitboxes := Component.find_component_array(user, HitboxComponent.get_component_name())
	for i in hitboxes.size():
		var hitbox := hitboxes[i] as HitboxComponent
		if hitbox == null:
			continue
		raycast.add_exception(hitbox.to_collision_object())
