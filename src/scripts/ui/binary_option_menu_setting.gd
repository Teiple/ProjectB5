extends Setting
class_name BinaryOptionMenuSetting

@onready var binary_option_menu: BinaryOptionMenu = $BinaryOptionMenu

func _ready() -> void:
	binary_option_menu.init_options()
	super._ready()

func set_current_value(value):
	binary_option_menu.set_enabled(value)

func get_current_value():
	return binary_option_menu.get_enabled()
