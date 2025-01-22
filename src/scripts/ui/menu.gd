extends Control
class_name Menu

@onready var menu_stack : MenuStack = get_parent() as MenuStack

enum MenuType{
	PAUSE_MENU,
	SETTINGS_MENU,
	MAIN_MENU,
	CREDIT_MENU
}
