extends ShapeCast3D
class_name ZoneInteractionComponent

@onready var player : Player = owner
@onready var update_timer : Timer = $UpdateTimer

func _ready():
	update_timer.timeout.connect(_on_update_timer_timeout)
	update_timer.start()

static func get_component_name() -> String:
	return "ZoneInteractionComponent"

func _on_update_timer_timeout():
	shape = player.get_expanded_collision_shape()
	position.y = player.collision_shape.shape.height * 0.5
	force_shapecast_update()
	for i in get_collision_count():
		var collider = get_collider(i)
		if collider is Zone:
			collider.enter(player)
