extends Node
class_name FrameByFrameDebugger
var next_frame = false
var mode_on = false

@export var enabled := false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Prevent from setting this true on the shipped product
	if Utils.is_game_exported() && enabled:
		enabled = false

func _unhandled_input(event):
	if enabled && event is InputEventMouseButton &&  event.pressed:
		if event.is_action_pressed("frame_debugger_toggle"):
			mode_on = !mode_on
		if get_tree().paused && event.is_action_pressed("frame_debugger_step"):
			next_frame = true

func _process(delta):
	if mode_on:
		get_tree().paused = true
		if next_frame:
			get_tree().paused = false
			next_frame = false
	else:
		get_tree().paused = false
