extends PooledItem
class_name WeaponProjectile

@export var projectile_length := 1.0
@export var move_speed := 50.0
@export var max_duration := 2.0
@export var first_ignore_distance := 0.5

@onready var raycast: RayCast3D = $RayCast3D
@onready var plane_mesh : MeshInstance3D = $MeshInstance3D

var start_position := Vector3.ZERO
var fly_direction := Vector3.ZERO
var weapon_stats : WeaponStats = null
var attacker : Character = null
var start_timemark := 0.0
var first_ignore : Array = [] # Array of hitboxes that will be ignored for the intial duration

var traveled_distance := 0.0

func _ready():
	raycast.target_position = Vector3(0, 0, -projectile_length)
	plane_mesh.position = Vector3(0, 0, -projectile_length * 0.5)

func on_item_taken_from_pool(set_up_info := {}):
	# Extract set up variables
	fly_direction = set_up_info.get("fly_direction", Vector3.ZERO)
	start_position = set_up_info.get("start_position", Vector3.ZERO)
	weapon_stats = set_up_info.get("weapon_stats", null)
	move_speed = set_up_info.get("projectile_speed", 5.0)
	first_ignore = set_up_info.get("first_ignore", [])
	# Ignore some hitboxes at the start so the shooter won't shoot themselves
	raycast.clear_exceptions()
	for hitbox in first_ignore:
		if hitbox is CollisionObject3D:
			raycast.add_exception(hitbox)
	
	attacker = null # Temporary
	start_timemark = CustomTime.physics_time
	# Set up transform
	global_position = start_position
	look_at(global_position + fly_direction)
	# Start timer
	start_timemark = CustomTime.physics_time
	traveled_distance = 0.0

func _physics_process(delta: float) -> void:
	if !self.active:
		return
	
	if CustomTime.physics_time - start_timemark > max_duration:
		pool.release(self)
		return
	
	# Turn on the check back for ignored hitboxes
	# This will clear all exceptions
	if traveled_distance > first_ignore_distance:
		raycast.clear_exceptions()
	
	raycast.force_raycast_update()
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		var collision_point = raycast.get_collision_point()
		var collision_normal = raycast.get_collision_normal()
		if collider is StaticBody3D:
			pass
		elif collider is HitboxComponent:
			if weapon_stats != null:
				var atk_info = AttackInfo.new()
				atk_info.damage = weapon_stats.damage_per_projectile
				atk_info.attack_type = AttackInfo.AttackType.BULLET
				atk_info.knock_back_vector = -collision_normal * weapon_stats.knock_back_force_per_projectile
				atk_info.attacker = attacker
				atk_info.receiver = collider.get_character_owner()
				atk_info.origin = start_position
				atk_info.hit_point = collision_point
				collider.receive_attack(atk_info)
		visible = false
		pool.release(self)
	else:
		# This need to be last so the projectile don't missss the first physics frame
		var d = move_speed * delta
		global_position += fly_direction * d
		traveled_distance += d
