extends Component
class_name WeaponRaycastComponent

@export var starting_point_transform : Node3D = null
@export var forward_shooting_direction_transform : Node3D = null
## For spawning bullet trails
@export var starting_point_transform_visual : Node3D = null

@onready var raycast : RayCast3D = $RayCast3D
@onready var weapon : Weapon = owner

var max_distance := 100.0
var shooting_angle := Vector2.ZERO

static func get_component_name() -> String:
	return "WeaponRaycastComponent"

func _ready():
	super._ready()
	if !weapon.is_node_ready():
		await weapon.ready
	weapon.fire_requested.connect(_on_fire_requested)
	#weapon_dynamic_angle_component = Component.find_component(weapon, "WeaponDynamicAngleComponent")

func _on_fire_requested():
	# Only apply if the weapon is hitscan
	if !weapon.weapon_stats.hitscan:
		return
	for i in weapon.weapon_stats.projectiles_per_shot:
		shoot_one_shot()

func _aim_raycast():
	var user_is_player = weapon.state_machine.get_current_state_path() == "UsedByPlayer/Selected"
	# if not, user is an npc
	if user_is_player:
		add_exceptions_for_user(Global.current_game().player())
	
	var start_pnt = starting_point()
	var shoot_dir = shooting_direction()
	
	raycast.global_position = start_pnt
	raycast.target_position = Vector3(0.0, 0.0, -max_distance)
	raycast.look_at(start_pnt + shoot_dir)
	
	shooting_angle = Vector2(randf_range(-weapon.weapon_stats.max_angle, weapon.weapon_stats.max_angle), randf_range(-weapon.weapon_stats.max_angle, weapon.weapon_stats.max_angle))
	
	raycast.rotate_x(shooting_angle.x)
	raycast.rotate_y(shooting_angle.y)
	
	raycast.force_raycast_update()

func shoot_one_shot():
	_aim_raycast()
	
	var bullet_trail_end_point := raycast.global_position - raycast.global_basis.z * max_distance
	if raycast.is_colliding():
		var collision_point = raycast.get_collision_point()
		bullet_trail_end_point = collision_point
		
		var hitbox := raycast.get_collider() as HitboxComponent
		
		if hitbox != null:
			var attack_info = AttackInfo.new()
			attack_info.attack_type = AttackInfo.AttackType.BULLET
			attack_info.damage = weapon.weapon_stats.damage_per_projectile
			attack_info.knock_back_vector = -raycast.global_basis.z * weapon.weapon_stats.knock_back_force_per_projectile
			attack_info.origin = raycast.global_position
			attack_info.hit_point = collision_point
			attack_info.attacker = self
			attack_info.receiver = hitbox
			
			hitbox.receive_attack(attack_info)
	
	var bullet_trail_pool := Global.current_game().get_node_or_null(BulletTrailPool.get_pool_name()) as BulletTrailPool
	var set_up_info := {
		"start_position" :  starting_point_transform_visual.global_position if starting_point_transform_visual else raycast.global_position,
		"end_position" : bullet_trail_end_point,
		# future: attacker
	}
	# Create a bullet trail
	bullet_trail_pool.get_pooled_item(set_up_info)

func starting_point() -> Vector3:
	var use_player_camera_for_starting_point = weapon.state_machine.get_current_state_path() == "UsedByPlayer/Selected"
	
	if use_player_camera_for_starting_point:
		return Global.current_game().player().camera.global_position
	if starting_point_transform != null:
		return starting_point_transform.global_position
	return Vector3.ZERO

func shooting_direction() -> Vector3:
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
