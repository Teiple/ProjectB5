extends PlayerState

@export var mantle_normalized_speed := 1.5
@export var mantle_curve : Curve
@export var push_speed := 1.0

@onready var base_state : PlayerStateMove = get_parent()

var target_position = null
var start_position := Vector3.ZERO
var direction_before_mantle := Vector3.ZERO
var offset := 0.0

func unhandled_input(event):
	base_state.unhandled_input(event)
	
func physics_process(delta):
	pass

func process(delta):
	offset += mantle_normalized_speed * delta
	offset = clampf(offset, 0.0, 1.0)
	var weight = mantle_curve.sample(offset)
	player.global_position = lerp(start_position, target_position, weight)
	if offset == 1.0:
		player.velocity = direction_before_mantle * push_speed
		_state_machine.transition_to("Move/Idle")
		return
	#base_state.process(delta)

func enter(msg := {}):
	base_state = get_parent()
	
	start_position = player.global_position
	target_position = msg.get("mantle_position", null)
	
	player.mantle_started.emit(target_position)
	
	if target_position == null:
		target_position = start_position
	
	direction_before_mantle = -player.global_transform.basis.z * Vector3(1.0, 0.0, 1.0)
	offset = 0.0
	player.set_collision(false)

func exit():
	player.mantle_finished.emit()
	
	player.set_collision(true)
