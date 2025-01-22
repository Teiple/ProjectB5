extends Control
class_name Setting

@export var game_settings_callback := ""
@export var setting_data_section := ""
@export var setting_data_label := "" 

func _ready() -> void:
	load_setting()
	apply_setting()

func get_current_value() -> Variant:
	return null

func set_current_value(value):
	pass

func save_setting():
	var settings := GameSettings.load_settings()
	if !settings.has(setting_data_section):
		settings[setting_data_section] = {}
	settings[setting_data_section][setting_data_label] = get_current_value()
		
	GameSettings.save_settings(settings)

func load_setting():
	var settings := GameSettings.load_settings()
	if settings.has(setting_data_section) && typeof(settings[setting_data_section]) == TYPE_DICTIONARY \
	&& settings[setting_data_section].has(setting_data_label):
		var val = settings[setting_data_section][setting_data_label]
		set_current_value(val)

func apply_setting():
	GameSettings.call(game_settings_callback, get_current_value())
