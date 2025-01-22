extends PooledItem
class_name BulletTrail

@export var move_speed := 20.0
@export var max_duration := 1.0
var start_position : Vector3 = Vector3.ZERO
var end_position : Vector3 = Vector3.ZERO
var start_timemark := 0.0

func on_item_taken_from_pool(set_up_info := {}):
	# Extract set up variables
	start_position = set_up_info.get("start_position", Vector3.ZERO)
	end_position = set_up_info.get("end_position", Vector3.ZERO)
	# Set up transform
	global_position = start_position
	look_at(end_position)
	# Start timer
	start_timemark = CustomTime.physics_time

func _process(delta):
	if !self.active:
		return
	
	if CustomTime.time - start_timemark > max_duration:
		pool.release(self)
		return
	
	global_position = global_position.move_toward(end_position, move_speed * delta)
	if (global_position - end_position).length_squared() < 0.01:
		pool.release(self)
