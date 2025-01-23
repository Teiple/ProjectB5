extends Node3D
class_name Component

@export var unique : bool = true

const COMPONENT_ARRAY_SUFFIX = "_array"

func _ready():
	assign_component_to_owner()

func assign_component_to_owner():
	if owner == null:
		return
	if unique && !owner.has_meta(get_component_name()):
		owner.set_meta(get_component_name(), self)
		return
	if !unique:
		var component_arr = get_component_name() + COMPONENT_ARRAY_SUFFIX 
		if !owner.has_meta(component_arr):
			owner.set_meta(component_arr, [self])
			return
		var arr = owner.get_meta(component_arr)
		if arr is Array:
			arr.push_back(self)

static func get_component_name() -> String:
	assert("This component didn't implement get_component_name() method")
	return "" 

static func get_component_array_name() -> String:
	return get_component_name() + COMPONENT_ARRAY_SUFFIX 
	
static func find_component(node : Node, component_name : String):
	if node.has_meta(component_name):
		return node.get_meta(component_name)
	return null

# Please don't use get_component_array_name() for the component_name
static func find_component_array(node : Node, component_name : String) -> Array:
	var component_arr = component_name + COMPONENT_ARRAY_SUFFIX
	if node.has_meta(component_arr):
		var arr = node.get_meta(component_arr)
		if arr is Array:
			return arr
	return []
