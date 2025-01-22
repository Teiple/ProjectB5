extends Node

signal scene_changing
signal scene_changed

@export_file("*.tscn") var title_scene_path : String = ""
@export var game_title : String = "ProjectA"
@export var save_file_path : String = "user://game_data.dat"

var current_scene : Node = null
var previous_scene_path : String = ""

func _ready():
	var scene_root = get_tree().root
	current_scene = scene_root.get_child(scene_root.get_child_count() - 1)
	get_window().title = game_title

func current_game() -> CurrentGame:
	return current_scene as CurrentGame

func set_mouse_visibility(mouse_visible : bool):
	if mouse_visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func mouse_visible() -> bool:
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		return true
	elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		return false
	return false

func get_screen_size() -> Vector2:
	var screen_size = get_viewport().get_visible_rect().size
	return screen_size

func get_aspect_ratio() -> float:
	var screen_size = get_viewport().get_visible_rect().size
	return screen_size.x / screen_size.y

func goto_scene(path : String, save_player_state : bool = false):
	scene_changing.emit()
	call_deferred('_deferred_goto_scene', path, save_player_state)
	scene_changed.emit()

func _deferred_goto_scene(path : String, save_player_state : bool):
	previous_scene_path = current_scene.scene_file_path
	
	current_scene.free()
	var s = ResourceLoader.load(path)
	current_scene = s.instantiate()
	get_tree().root.add_child(current_scene, true)
	get_tree().current_scene = current_scene

func restart_scene():
	unpause()
	goto_scene(current_scene.scene_file_path, false)

func quit():
	get_tree().quit()

func save_data(data_name : String, data_value):
	var data_dct : Dictionary
	if FileAccess.file_exists(save_file_path):
		var file = FileAccess.open(save_file_path, FileAccess.READ)
		data_dct = file.get_var()
		file.close()
	data_dct[data_name] = data_value
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	file.store_var(data_dct)
	file.close()

func get_data(data_name : String):
	if FileAccess.file_exists(save_file_path):
		var file = FileAccess.open(save_file_path, FileAccess.READ)
		var data_dct = file.get_var()
		file.close()
		return data_dct.get(data_name, null)
	else:
		return null

func pause():
	get_tree().paused = true

func unpause():
	get_tree().paused = false
