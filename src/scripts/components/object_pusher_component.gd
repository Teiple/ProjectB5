extends Component
class_name PushComponent

@export var radius_offset := 0.02
@export var ground_offset := 0.1
@export var height_offset := 0.2
@export var push_force := 1200.0

@onready var player : Player = owner
@onready var body_shape_cast: ShapeCast3D = $BodyShapeCast
@onready var ground_shape_cast: ShapeCast3D = $GroundShapeCast

var is_mantling := false
var grab_compoment : GrabComponent = null

static func get_component_name():
	return "PushComponent"

func _ready() -> void:
	super._ready()
	if !player.is_node_ready(): 
		await player.ready
	player.mantle_started.connect(func(pos): is_mantling = true)
	player.mantle_finished.connect(func(): is_mantling = false)
	grab_compoment = Component.find_component(player.weapon_controller, GrabComponent.get_component_name())

func _physics_process(delta: float) -> void:
	if is_mantling || player.target_horizontal_velocity.length_squared() < 0.0001:
		return
	var cylinder_shape = CylinderShape3D.new()
	cylinder_shape.height = player.collision_shape.shape.height - height_offset * 2.0
	cylinder_shape.radius = player.collision_shape.shape.radius + radius_offset
	body_shape_cast.position.y = player.collision_shape.shape.height * 0.5
	body_shape_cast.shape = cylinder_shape
	body_shape_cast.force_shapecast_update()
	for i in body_shape_cast.get_collision_count():
		var collider = body_shape_cast.get_collider(i)
		var collision_point = body_shape_cast.get_collision_point(i)
		var collision_normal = body_shape_cast.get_collision_normal(i)
		if collider is PhysicsObject:
			# We drop the object if it collided with use while being carried
			#if grab_compoment != null && grab_compoment.current_object == collider:
				#grab_compoment.release_object()
			collider.apply_central_force(-collision_normal * push_force * delta)

func is_colliding_with(collider : PhysicsBody3D):
	var cylinder_shape = CylinderShape3D.new()
	cylinder_shape.height = player.collision_shape.shape.height - height_offset * 2.0
	cylinder_shape.radius = player.collision_shape.shape.radius + radius_offset
	body_shape_cast.shape = cylinder_shape
	body_shape_cast.position.y = player.collision_shape.shape.height * 0.5
	body_shape_cast.force_shapecast_update()
	for i in body_shape_cast.get_collision_count():
		var col = body_shape_cast.get_collider(i)
		if col == collider:
			return true
	return false

func is_standing_on(collider : PhysicsBody3D):
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = player.collision_shape.shape.radius - radius_offset
	ground_shape_cast.shape = sphere_shape
	ground_shape_cast.position.y = player.collision_shape.shape.radius * 0.5 - ground_offset
	ground_shape_cast.force_shapecast_update()
	for i in ground_shape_cast.get_collision_count():
		var col = ground_shape_cast.get_collider(i)
		if col == collider:
			return true
	return false
