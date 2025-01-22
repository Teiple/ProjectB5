extends Component
class_name PlayerStaticColliderComponent

var current_base_shape : Shape3D = null
@export var enabled := false
@onready var player : Player = owner
@onready var collision_shape: CollisionShape3D = $StaticBody3D/CollisionShape3D

func _ready() -> void:
	super._ready()
	if player.is_node_ready():
		await player.ready

static func get_component_name():
	return "PlayerStaticColliderComponent"

func get_grown_collision_shape(current_shape : CapsuleShape3D, amount : float) -> CapsuleShape3D:
	var grown : CapsuleShape3D = current_shape.duplicate()
	grown.radius = current_shape.radius - amount
	grown.height = current_shape.height - amount * 2.0
	return grown

func _physics_process(delta: float) -> void:
	if !enabled:
		collision_shape.disabled = true
		return
	collision_shape.disabled = false
	if current_base_shape != player.collision_shape.shape:
		current_base_shape = player.collision_shape.shape
		collision_shape.shape = get_grown_collision_shape(current_base_shape, 0.1)
