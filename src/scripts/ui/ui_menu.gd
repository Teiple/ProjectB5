extends Control
class_name MenuStack

## The menu that will appear when the user presses "Esc" 
@export var start_menu  : Menu.MenuType = Menu.MenuType.PAUSE_MENU
@export var preloaded_menus : Dictionary = {
	Menu.MenuType.PAUSE_MENU : preload("res://src/scenes/ui/pause_menu.tscn"),
	Menu.MenuType.SETTINGS_MENU : preload("res://src/scenes/ui/settings_menu.tscn"),
}

var menus : Dictionary = {}

var stack : Array[Menu] = []

func _ready() -> void:
	mouse_filter = MouseFilter.MOUSE_FILTER_IGNORE
	for menu_type in preloaded_menus:
		menus[menu_type] = preloaded_menus[menu_type].instantiate() as Menu
		menus[menu_type].visible = false
		add_child(menus[menu_type])
	
func append(menu_type : Menu.MenuType):
	if menus.has(menu_type):
		if stack.size() > 0:
			stack.back().visible = false
		else: # Open
			Global.pause()
			Global.set_mouse_visibility(true)
			mouse_filter = MouseFilter.MOUSE_FILTER_STOP
		stack.append(menus[menu_type])
		stack.back().visible = true

func pop():
	if stack.size() > 0:
		stack.back().visible = false
		stack.pop_back()
	if stack.size() > 0:
		stack.back().visible = true
	else: # Close
		Global.unpause()
		Global.set_mouse_visibility(false)
		mouse_filter = MouseFilter.MOUSE_FILTER_IGNORE

func clear():
	for menu in stack:
		menu.visible = false
	stack.clear()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		if stack.size() > 0:
			# Clear current menu
			pop()
		else:
			# Starting pushing menu
			append(start_menu)
