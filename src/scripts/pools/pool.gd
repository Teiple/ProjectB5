extends Node
class_name Pool

@export var max_size := 10
@export var item_scene : PackedScene = null
var pool_array : Array[PooledItem] = []

# Debugging
var runtime_creation_count := 0
var runtime_deletion_count := 0

func _ready():
	for i in max_size:
		var item := create_pooled_item()
		pool_array.push_back(item)

## Must override
static func get_pool_name() -> String:
	assert("This node didn't override get_pool_name() method")
	return ""

func get_pooled_item(set_up_info:={}) -> PooledItem:
	var item : PooledItem
	if !pool_array.is_empty():
		item = pool_array.pop_front()
	else:
		# Create a new item if the pool was empty
		runtime_creation_count += 1
		item = create_pooled_item()
		# We don't need push this item into the pool array
		# since it will immediately become active
	on_take_from_pool(item, set_up_info)
	return item

func release(item : PooledItem):
	# Destroy the returning item if the pool was full
	if pool_array.size() >= max_size:
		runtime_deletion_count += 1
		on_destroy_pool_object(item)
		return
	
	pool_array.push_back(item)
	on_returned_to_pool(item)

# override
func create_pooled_item() -> PooledItem:
	var item := item_scene.instantiate() as PooledItem
	item.visible = false
	item.active = false
	item.pool = self
	self.add_child(item)
	return item

func on_take_from_pool(item : PooledItem, set_up_info := {}):
	item.on_item_taken_from_pool(set_up_info)
	item.visible = true
	item.active = true

func on_returned_to_pool(item : PooledItem):
	item.visible = false
	item.active = false

func on_destroy_pool_object(item : PooledItem):
	item.visible = false
	item.active = false
	item.queue_free()

func get_info() -> String:
	var info := "%s:\n" % get_pool_name()
	info += "pool max size: %d \n" % max_size
	info += "pool size: %d \n" % pool_array.size()
	info += "runtime creation: %d \n" % runtime_creation_count
	info += "runtime deletion: %d \n" % runtime_deletion_count
	return info
