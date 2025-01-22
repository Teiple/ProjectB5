extends Area3D
class_name Zone

signal zone_entered(who : Node3D)

var enabled := false
var initial_collision_layer := 0
var initial_collision_mask := 0

func _ready():
	initial_collision_layer = collision_layer
	initial_collision_mask = collision_mask

func set_enabled(val : bool):
	enabled = val
	if val == true:
		collision_layer = initial_collision_layer
		collision_mask = initial_collision_mask
	else:
		collision_layer = 0
		collision_mask = 0

func enter(who : Node3D):
	zone_entered.emit(who)

func toggle_debug_view(enabled : bool):
	var debug_collision_shapes_component := Component.find_component(self, DebugCollisionShapesComponent.get_component_name()) as DebugCollisionShapesComponent
	debug_collision_shapes_component.toggle_debug_view(enabled)
