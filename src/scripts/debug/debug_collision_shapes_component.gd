extends Component
class_name DebugCollisionShapesComponent

@export var debugging := false

var debug_shape_rids : Array[RID] = []
var debug_shape_source_nodes : Array[Node3D] = []
var debug_shape_source_shapes : Array[Shape3D] = []

func _ready():
	super._ready()
	if debugging:
		toggle_debug_view(true)

static func get_component_name() -> String:
	return "DebugCollisionShapesComponent"

func toggle_debug_view(enabled : bool):
	debugging = enabled
	if !debug_shape_rids.is_empty():
		for i in debug_shape_rids.size():
			var debug_shape_rid = debug_shape_rids[i]
			RenderingServer.instance_set_visible(debug_shape_rid, debugging)
		return
	if owner == null:
		return
	for i in owner.get_child_count():
		var collision_shape = owner.get_child(i)# as CollisionShape3D
		if collision_shape is not CollisionShape3D && collision_shape is not ShapeCast3D:
			continue
		
		if collision_shape.shape == null:
			continue
		
		var debug_mesh = collision_shape.shape.get_debug_mesh()
		var base = debug_mesh.get_rid()
		var scenario = collision_shape.get_world_3d().scenario
		
		var debug_instance_rid := RenderingServer.instance_create2(base, scenario)
		debug_shape_rids.push_back(debug_instance_rid)
		debug_shape_source_nodes.push_back(collision_shape)
		debug_shape_source_shapes.push_back(collision_shape.shape)
		RenderingServer.instance_set_transform(debug_instance_rid, collision_shape.global_transform)
		
func _debug_process(delta):
	for i in debug_shape_rids.size():
		var debug_shape_rid = debug_shape_rids[i]
		var debug_shape_source_node = debug_shape_source_nodes[i]
		if debug_shape_source_node is CollisionShape3D && debug_shape_source_node is ShapeCast3D:
			var debug_shape_source_shape = debug_shape_source_shapes[i]
			if debug_shape_source_node.shape != debug_shape_source_shape:
				RenderingServer.free_rid(debug_shape_rid)
				var debug_mesh = debug_shape_source_node.shape.get_debug_mesh()
				var base = debug_mesh.get_rid()
				var scenario = debug_shape_source_node.get_world_3d().scenario
				debug_shape_rid = RenderingServer.instance_create2(base, scenario)
				debug_shape_rids[i] = debug_shape_rid
				debug_shape_source_shape = debug_shape_source_node.shape
				debug_shape_source_shapes[i] = debug_shape_source_shape
		RenderingServer.instance_set_transform(debug_shape_rid, debug_shape_source_node.global_transform)
		
func _process(delta):
	if debugging:
		_debug_process(delta)
