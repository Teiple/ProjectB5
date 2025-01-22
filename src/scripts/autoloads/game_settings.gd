extends Node
# GameSettings is where all the settings logic go
# It is NOT responsible for saving and loading settings

const GAME_SETTINGS_FILE_PATH = "user://settings.json"

var current_resolution : Vector2i = Vector2i(0, 0)

const FPS_UNLIMITED = "Unlimited"

func load_settings() -> Dictionary:
	var fread = FileAccess.open(GAME_SETTINGS_FILE_PATH, FileAccess.READ)
	if fread == null:
		return {}
	var file_content = fread.get_as_text()
	
	var json = JSON.new()
	if json.parse(file_content) != OK || typeof(json.data) != TYPE_DICTIONARY:
		return {}
	
	return json.data as Dictionary

func save_settings(settings : Dictionary):
	var json_string = JSON.stringify(settings, "\t")
	var fwrite = FileAccess.open(GAME_SETTINGS_FILE_PATH, FileAccess.WRITE)
	#print_debug(FileAccess.get_open_error())
	fwrite.store_string(json_string)

func set_master_volume(value : float): # value should be in linear scale
	var bus_idx = AudioServer.get_bus_index("Master")
	var volume_db = linear_to_db(value)
	AudioServer.set_bus_volume_db(bus_idx, volume_db)

func set_sfx_volume(value : float): # value should be in linear scale
	var bus_idx = AudioServer.get_bus_index("SFX")
	var volume_db = linear_to_db(value)
	AudioServer.set_bus_volume_db(bus_idx, volume_db)

func set_resolution(value : String):
	var target_res := value.split("x", true, 1)
	if target_res.size() == 2:
		var new_resolution = Vector2i(int(target_res[0]), int(target_res[1]))
		_set_resolution(new_resolution)

func set_mouse_filter(value : bool):
	if Global.current_game() && Global.current_game().player():
		Global.current_game().player().head.mouse_filter = value

func set_mouse_sensitivity(value : float):
	if Global.current_game() && Global.current_game().player():
		Global.current_game().player().head.mouse_sensitivity = value

func set_vsync(value : bool):
	if value:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func set_fullscreen(value : bool):
	if value:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		if current_resolution != Vector2i.ZERO:
			_set_resolution(current_resolution)

func _set_resolution(res : Vector2i):
	res = clamp(res, Vector2i(0, 0), DisplayServer.screen_get_size())
	current_resolution = res
	get_tree().root.content_scale_size = res
	if get_tree().root.mode == Window.MODE_WINDOWED:
		get_tree().root.size = res
		get_tree().root.position = DisplayServer.screen_get_size() / 2.0 - res / 2.0

func set_fps_limit(value : String):
	# E.g: "30 FPS", "60 FPS"
	if value == FPS_UNLIMITED:
		Engine.max_fps = 0
		return
	var splits = value.split(" ", false, 1)
	if splits.size() != 2:
		return
	var fps_limit = int(splits[0])
	Engine.max_fps = fps_limit

func set_rendering_scale(value : float):
	get_tree().root.scaling_3d_scale = value
