extends Node3D
class_name PooledItem

# If upto the item itself to detect when it's inactive
# and return to its proper pool through pool.release()
var active := false
# This must be set by the pool when it create this item 
var pool : Pool = null

## Use for set up item's property before (re-)adding it to the scene
func on_item_taken_from_pool(set_up_info:={}):
	pass
