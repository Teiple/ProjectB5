extends Character
class_name Player

signal land(height : float)
signal jump
#signal mantle(mantle_position : Vector3)
signal mantle_started(mantle_position : Vector3)
signal mantle_finished()
signal step

@export var gravity := 30.0
@export var move_speed := 5.0
@export var jump_height := 1.0
@export var move_accel := 30.0
@export var move_decel := 30.0
#@export_range(0.0, 1.0, 0.001) var in_air_speed_reduction := 0.5
@export var in_air_acceleration := 12.0
@export_range(0.0, 1.0, 0.001) var crouch_speed_reduction := 0.35
@export var coyote_time := 0.2
@export var jump_buffer_time := 0.2
@export var standing_collision_shape : CapsuleShape3D = CapsuleShape3D.new()
@export var crouching_collision_shape : CapsuleShape3D = CapsuleShape3D.new()
@export var lower_crouching_collision_shape : CapsuleShape3D = CapsuleShape3D.new()
## The amount of shrinking from the actual collision shape to use in space-checking
#@export var space_shape_offset := 0.05
@export var shrinked_grown_shape_offset := 0.025

@onready var step_offset_raycast_pivot : Node3D = %StepOffsetRaycastPivot
@onready var step_up_raycast : RayCast3D = %StepUpRaycast
@onready var step_down_raycast : RayCast3D = %StepDownRaycast
@onready var mantle_raycast : RayCast3D = %MantleRaycast
@onready var step_offset_space_check : ShapeCast3D = %StepOffsetSpaceCheck

@onready var head : PlayerHead = %Head
@onready var collision_shape : CollisionShape3D = $CollisionShape3D
@onready var state_machine : StateMachine = %StateMachine

@onready var crouch_toggle_space_check : ShapeCast3D = %CrouchToggleSpaceCheck

@onready var height_check_raycast : RayCast3D = %HeightCheckRaycast
@onready var camera : Camera3D = %Camera

@onready var weapon_controller : WeaponController = %WeaponController

var was_on_floor := false
var target_horizontal_velocity : Vector3 = Vector3.ZERO

# Debugging
@onready var third_person_camera : Camera3D = %ThirdPersonCamera

var player_shapes : Array[CapsuleShape3D] = []

enum CollisionShape{
	STANDING = 0,
	CROUCHING = 1,
	LOWER_CROUCHING = 2,
	STANDING_SHRINKED = 3,
	CROUCHING_SHRINKED = 4,
	LOWER_CROUCHING_SHRINKED = 5,
	STANDING_GROWN = 6,
	CROUCHING_GROWN = 7,
	LOWER_CROUCHING_GROWN = 8,
}

func _ready():
	super._ready()
	_init_capsule_shapes() 
	collision_shape.shape = player_shapes[CollisionShape.STANDING]

func _init_capsule_shapes():
	player_shapes.resize(CollisionShape.keys().size())
	player_shapes[CollisionShape.STANDING] = standing_collision_shape
	player_shapes[CollisionShape.CROUCHING] = crouching_collision_shape
	player_shapes[CollisionShape.LOWER_CROUCHING] = lower_crouching_collision_shape
	player_shapes[CollisionShape.STANDING_SHRINKED] = _get_shrinked_capsule_shape(standing_collision_shape)
	player_shapes[CollisionShape.CROUCHING_SHRINKED] = _get_shrinked_capsule_shape(crouching_collision_shape)
	player_shapes[CollisionShape.LOWER_CROUCHING_SHRINKED] = _get_shrinked_capsule_shape(lower_crouching_collision_shape)
	player_shapes[CollisionShape.STANDING_GROWN] = _get_grown_capsule_shape(standing_collision_shape)
	player_shapes[CollisionShape.CROUCHING_GROWN] = _get_grown_capsule_shape(crouching_collision_shape)
	player_shapes[CollisionShape.LOWER_CROUCHING_GROWN] = _get_grown_capsule_shape(lower_crouching_collision_shape)

func is_crouching():
	return collision_shape.shape != standing_collision_shape

func get_shrinked_collision_shape() -> CapsuleShape3D:
	var shape_idx = get_current_collision_shape_index()
	if shape_idx == CollisionShape.STANDING:
		return player_shapes[CollisionShape.STANDING_SHRINKED]
	if shape_idx == CollisionShape.CROUCHING:
		return player_shapes[CollisionShape.CROUCHING_SHRINKED]
	if shape_idx == CollisionShape.LOWER_CROUCHING:
		return player_shapes[CollisionShape.LOWER_CROUCHING_SHRINKED]
	return collision_shape.shape

func _get_shrinked_capsule_shape(current_shape : CapsuleShape3D) -> CapsuleShape3D:
	var shrinked : CapsuleShape3D = current_shape.duplicate()
	shrinked.radius = current_shape.radius - shrinked_grown_shape_offset
	shrinked.height = current_shape.height - shrinked_grown_shape_offset * 2.0
	return shrinked

func _get_grown_capsule_shape(current_shape : CapsuleShape3D) -> CapsuleShape3D:
	var shrinked : CapsuleShape3D = current_shape.duplicate()
	shrinked.radius = current_shape.radius + shrinked_grown_shape_offset
	shrinked.height = current_shape.height + shrinked_grown_shape_offset * 2.0
	return shrinked

func get_current_collision_shape_index() -> CollisionShape:
	for i in [CollisionShape.STANDING, CollisionShape.CROUCHING, CollisionShape.LOWER_CROUCHING]:
		if player_shapes[i] == collision_shape.shape:
			return i
	return -1

func get_expanded_collision_shape() -> CapsuleShape3D:
	var shape_idx = get_current_collision_shape_index()
	if shape_idx == CollisionShape.STANDING:
		return player_shapes[CollisionShape.STANDING_GROWN]
	if shape_idx == CollisionShape.CROUCHING:
		return player_shapes[CollisionShape.CROUCHING_GROWN]
	if shape_idx == CollisionShape.LOWER_CROUCHING:
		return player_shapes[CollisionShape.LOWER_CROUCHING_GROWN]
	return collision_shape.shape

func get_shrinked_standing_collision_shape() -> CapsuleShape3D:
	return player_shapes[CollisionShape.STANDING_SHRINKED]

func get_shrinked_crouching_collision_shape() -> CapsuleShape3D:
	return player_shapes[CollisionShape.CROUCHING_SHRINKED]

func get_shrinked_lower_crouching_collision_shape() -> CapsuleShape3D:
		return player_shapes[CollisionShape.LOWER_CROUCHING_SHRINKED]

func switch_to_normal_crouching_mode():
	collision_shape.shape = player_shapes[CollisionShape.CROUCHING]
	collision_shape.position.y = collision_shape.shape.height * 0.5

func switch_to_lower_crouching_mode():
	collision_shape.shape = player_shapes[CollisionShape.LOWER_CROUCHING]
	collision_shape.position.y = collision_shape.shape.height * 0.5

func switch_to_standing_mode():
	collision_shape.shape = player_shapes[CollisionShape.STANDING]
	collision_shape.position.y = collision_shape.shape.height * 0.5

func rotate_local_y(angle : float):
	rotate_y(angle)

func get_jump_speed() -> float:
	return sqrt(2.0 * gravity * jump_height)

func get_fallen_height_from_velocity(y_velocity : float) -> float:
	if y_velocity > 0.0:
		return 0.0
	return y_velocity * y_velocity / (2.0 * gravity)

func set_collision(enabled : bool):
	collision_shape.disabled = !enabled

func toggle_third_person_view(enabled : bool):
	if enabled:
		third_person_camera.current = true
	else:
		camera.current = true

func toggle_collision_shape(enabled : bool):
	var debug_collision_shapes_component := Component.find_component(self, DebugCollisionShapesComponent.get_component_name()) as DebugCollisionShapesComponent
	if debug_collision_shapes_component == null:
		return
	debug_collision_shapes_component.toggle_debug_view(enabled)
