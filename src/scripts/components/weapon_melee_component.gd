extends Component
class_name WeaponMeleeComponent

@export var damage := 10.0
@export var knock_back_vector := 5.0
@export var starting_point_transform : Node3D = null
@export var forward_direction_transform : Node3D = null
@export var forward_offset := 0.3
@export var cast_length := 0.8

@onready var weapon : Weapon = owner
@onready var raycast : RayCast3D = $RayCast3D
@onready var shapecast : ShapeCast3D = $ShapeCast3D

var debugging := false
var debug_duration := 0.25
var debug_color := Color.CRIMSON

func _ready():
	super._ready()
	if !weapon.is_node_ready():
		await weapon.ready
	weapon.melee_requested.connect(_on_melee_requested)

static func get_component_name() -> String:
	return "WeaponMeleeComponent"

func _on_melee_requested():
	melee()

func melee():
	var user_is_player = weapon.state_machine.get_current_state_path() == "UsedByPlayer/Selected"
	# if not, user is an npc
	if user_is_player:
		add_exceptions_for_user(Global.current_game().player())
	
	var starting_point = starting_point()
	var forward_direction = forward()
	shapecast.global_position = starting_point + forward_direction * forward_offset
	shapecast.look_at(shapecast.global_position + forward_direction)
	shapecast.target_position = Vector3(0.0, 0.0, -cast_length)
	
	if debugging:
		if shapecast.shape is SphereShape3D:
			var detail_amount := 3
			for i in detail_amount + 1:
				DebugDraw3D.draw_sphere(shapecast.global_position + forward_direction * (1.0 * i / detail_amount) * cast_length, shapecast.shape.radius, debug_color, debug_duration)
	
	shapecast.force_shapecast_update()
	var hitboxes_collided := []
	var hitboxes_collision_points := []
	for i in shapecast.get_collision_count():
		var hitbox := shapecast.get_collider(i) as HitboxComponent
		if hitbox == null:
			continue
		# Check if the hitbox is behind something
		raycast.target_position = raycast.to_local(hitbox.global_position)
		raycast.force_raycast_update()
		if raycast.is_colliding():
			continue
		var collision_point = shapecast.get_collision_point(i)
		hitboxes_collided.push_back(hitbox)
		hitboxes_collision_points.push_back(collision_point)
	
	for i in hitboxes_collided.size():
		var hitbox := hitboxes_collided[i] as HitboxComponent
		var atk_info = AttackInfo.new()
		atk_info.attack_type = AttackInfo.AttackType.MELEE
		atk_info.damage = damage / hitboxes_collided.size()
		atk_info.origin = starting_point
		atk_info.hit_point = hitboxes_collision_points[i]
		atk_info.attacker = self
		atk_info.receiver = hitbox
		var knock_back_direction = starting_point.direction_to(hitboxes_collision_points[i])
		atk_info.knock_back_vector = knock_back_direction * knock_back_vector / hitboxes_collided.size()
		
		hitbox.receive_attack(atk_info)
		
		if debugging:
			DebugDraw3D.draw_square(hitboxes_collision_points[i], 0.1, debug_color, debug_duration)
			DebugDraw3D.draw_line(starting_point, hitboxes_collision_points[i], debug_color, debug_duration)
	
func starting_point() -> Vector3:
	var used_by_player = weapon.state_machine.get_current_state_path() == "UsedByPlayer/Selected"
	# if not then it is used by an npc
	if used_by_player:
		return Global.current_game().player().camera.global_position
	if starting_point_transform != null:
		return starting_point_transform.global_position
	return Vector3.ZERO

func forward() -> Vector3:
	var used_by_player = weapon.state_machine.get_current_state_path() == "UsedByPlayer/Selected"
	# if not then it is used by an npc
	if used_by_player:
		return -Global.current_game().player().camera.global_basis.z
	if forward_direction_transform != null:
		return -forward_direction_transform.global_basis.z
	return Vector3.ZERO

func toggle_debug_view(enabled : bool):
	debugging = enabled

func add_exceptions_for_user(user : Node3D):
	shapecast.clear_exceptions()
	var hitboxes := Component.find_component_array(user, HitboxComponent.get_component_name())
	for i in hitboxes.size():
		var hitbox := hitboxes[i] as HitboxComponent
		if hitbox == null:
			continue
		shapecast.add_exception(hitbox.to_collision_object())
