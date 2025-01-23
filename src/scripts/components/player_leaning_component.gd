extends Component
class_name PlayerLeaningComponent

var player : Player
# Check if the player would clip into anything
@onready var clipping_shapecast: ShapeCast3D = $ShapeCast3D
@export var max_lean_distance := 0.4
@export_range(0.0, 90.0, 0.001, "radians_as_degrees") var max_tilt_angle := 0.0872665
@export var lean_smooth_speed := 10.0

static func get_component_name() -> String:
	return "PlayerLeaningComponent"

func _ready():
	player = owner as Player

func _process(delta):
	clipping_shapecast.global_transform = player.head.global_transform
	
	var max_lean_amount := 0.0
	var target_lean_amount := 0.0
	var leaning := false
	if (Input.is_action_pressed("lean_left")):
		max_lean_amount = -max_lean_distance
		leaning = true
	elif (Input.is_action_pressed("lean_right")):
		max_lean_amount = max_lean_distance
		leaning = true
	if leaning:
		clipping_shapecast.target_position.x = max_lean_amount
		clipping_shapecast.force_shapecast_update()
		if (clipping_shapecast.is_colliding()):
			target_lean_amount = clipping_shapecast.to_local(clipping_shapecast.get_collision_point(0)).x
		else:
			target_lean_amount = max_lean_amount
	
	player.head.position.x = lerpf(player.head.position.x, target_lean_amount, lean_smooth_speed * delta) 
	var tilt_amount := player.head.position.x / max_lean_distance * max_tilt_angle
	player.camera.rotation.z = tilt_amount
	player.weapon_controller.rotation.z = tilt_amount * 2.0
