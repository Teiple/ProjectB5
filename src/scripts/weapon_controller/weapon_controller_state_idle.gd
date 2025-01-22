extends WeaponControllerState

@onready var base_state : WeaponControllerBaseState = get_parent()

func unhandled_input(event):
	base_state.unhandled_input(event)

func enter(msg := {}):
	weapon_controller.play_action("idle")

func process(delta):
	base_state.process(delta)
