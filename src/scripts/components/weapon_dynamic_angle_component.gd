extends Component
class_name WeaponDynamicAngleComponent

# There are three factors that affect the firing angle:
# + Player's movement (translation)
# + Player's aiming (looking)
# + How long it's been since the last shot fired

const MAX_PLAYER_MOVEMENT_SPEED_FACTOR := 4.0
const MAX_PLAYER_AIMING_SPEED_FACTOR := 0.1
const MAX_PLAYER_FIRING_TIME_FACTOR := 1.0
var normalized_dynamic_angle := Vector2.ZERO
var normalized_target_dynamic_angle := Vector2.ZERO
var dynamic_angle_velocity := Vector2.ZERO

@export var dynamic_angle_acceleration := 2.0
@export var dynamic_angle_speed := 5.0
@export var dynamic_angle_smooth_speed := 10.0
@export var active := true

@onready var dynamic_angle_intensity := 0.0
@onready var target_dynamic_angle_intensity := 0.0

@onready var weapon : Weapon = owner

static func get_component_name() -> String:
	return "WeaponDynamicAngleComponent"

# Other component has to call this function each frame to
# randomize angle smoothly. Returned Vector2 is the dynamic
# angle calcuated 
func calculate(delta : float, max_angle : float) -> Vector2:
	if !active:
		return Vector2.ZERO
	
	var player = Global.current_game().player()
	var player_movement_speed_factor = 0.25 * clampf(player.velocity.length() / MAX_PLAYER_MOVEMENT_SPEED_FACTOR, 0.0, 1.0)
	var player_aiming_speed_factor = 0.25 * clampf(Vector2(player.head.current_mouse_x, player.head.current_mouse_y).length() / MAX_PLAYER_AIMING_SPEED_FACTOR, 0.0, 1.0)
	var player_firing_time_factor = 0.25 * clampf(1.0 - (CustomTime.time - weapon.last_firing_time) / MAX_PLAYER_FIRING_TIME_FACTOR, 0.0, 1.0)
	
	# The first 25% is the default amount for idling 
	var target_dynamic_angle_intensity = 0.25 + player_movement_speed_factor + player_aiming_speed_factor + player_firing_time_factor
	dynamic_angle_intensity = lerpf(dynamic_angle_intensity, target_dynamic_angle_intensity, dynamic_angle_smooth_speed * delta)
	
	var target_velocity = normalized_dynamic_angle.direction_to(normalized_target_dynamic_angle) * dynamic_angle_speed
	dynamic_angle_velocity = lerp(dynamic_angle_velocity, target_velocity, dynamic_angle_acceleration * delta)
	normalized_dynamic_angle += dynamic_angle_velocity * delta
	if normalized_dynamic_angle.distance_squared_to(normalized_target_dynamic_angle) < 0.01:
		normalized_target_dynamic_angle = Utils.random_direction_2d() * randf_range(0.0, 1.0)
	
	return normalized_dynamic_angle * dynamic_angle_intensity * max_angle
