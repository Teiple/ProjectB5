extends Setting
class_name MultiOptionMenuSetting

@export var options : Array[String] = ["800x600", "1024x768", "1280x720", "1980x1080"]
@onready var multi_option_menu: MultiOptionMenu = $MultiOptionMenu

func _ready() -> void:
	# Load the options up first, before selecting it
	multi_option_menu.init_options(options)
	super._ready()

func set_current_value(value):
	multi_option_menu.set_option(value)

func get_current_value():
	return multi_option_menu.get_option()
