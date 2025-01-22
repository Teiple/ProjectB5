extends Menu
class_name SettingMenu

@export var settings : Array[Setting] = []
@onready var apply_button: Button = %ApplyButton
@onready var return_button: Button = %ReturnButton

func _ready() -> void:
	pass

func _on_apply_button_pressed() -> void:
	for setting in settings:
		setting.apply_setting()
		# Overkill
		setting.save_setting()

func _on_return_button_pressed() -> void:
	menu_stack.pop()
