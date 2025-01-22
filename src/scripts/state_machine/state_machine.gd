extends Node
class_name StateMachine
# Generic State Machine. Initializes states and delegates engine callbacks
# (_physics_process, _unhandled_input) to the active state.

signal transitioned(state_path)

## The state the state machine begins with, must be set beforehand.
@export_node_path("FSMState") var initial_state : NodePath
@onready var state: FSMState = get_node(initial_state) :
	set = set_state
@onready var _state_name: String = state.name

@export_group("Debug")
## Current state name will be displayed using this Label3D.
@export_node_path("Label3D") var state_name_display_path : NodePath
@onready var state_name_display : Label3D = get_node_or_null(state_name_display_path)

var queued_state_path : String = ""
var last_state : String = ""

func _init() -> void:
	add_to_group("state_machine")

func _ready() -> void:
	await owner.ready
	state.enter()

func _unhandled_input(event: InputEvent) -> void:
	state.unhandled_input(event)

func _process(delta: float) -> void:
	state.process(delta)
	
	if state_name_display:
#		state_name_display.text = _state_name
		state_name_display.text = last_state + "->" + _state_name

func _physics_process(delta: float) -> void:
	state.physics_process(delta)

func transition_to(target_state_path: String, msg: Dictionary = {}) -> void:
	if not has_node(target_state_path):
		return
	
	last_state = _state_name 
	var target_state := get_node_or_null(target_state_path)
	queued_state_path = target_state_path
	
	state.exit()
	self.state = target_state
	state.enter(msg)
	emit_signal("transitioned", target_state_path)

func set_state(value: FSMState) -> void:
	state = value
	_state_name = state.name

func get_state_by_name(state_name : String) -> FSMState:
	return find_child(state_name)

func get_current_state_name() -> String:
	if state == null:
		return ""
	else:
		return state.name

func get_current_state_path() -> String:
	if state == null:
		return ""
	else:
		return get_path_to(state)

func is_in_one_of_states(state_paths : Array, match_pattern : bool = false) -> bool:
	var current_state_path = get_current_state_path()
	for path in state_paths:
		if current_state_path == path:
			return true
		elif match_pattern && current_state_path.match(path):
			return true
	return false
 
