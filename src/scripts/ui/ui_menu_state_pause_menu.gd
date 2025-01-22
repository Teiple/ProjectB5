extends Menu

@onready var resume_button : Button = %ResumeButton
@onready var restart_button : Button = %RestartButton
@onready var settings_button : Button = %SettingsButton
@onready var exit_button : Button = %ExitButton

func _ready():
	resume_button.pressed.connect(on_resume_button_pressed)
	restart_button.pressed.connect(on_restart_button_pressed)
	exit_button.pressed.connect(on_exit_button_pressed)
	settings_button.pressed.connect(on_settings_button_pressed)

func on_resume_button_pressed():
	menu_stack.pop()

func on_restart_button_pressed():
	Global.restart_scene()

func on_exit_button_pressed():
	Global.quit()

func on_settings_button_pressed():
	menu_stack.append(MenuType.SETTINGS_MENU)
