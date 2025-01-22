extends WeaponControllerState


func enter(msg := {}):
	# Needed to call for the reset pose here for later transitions 
	weapon_controller.play_action(weapon_controller.arms_reset_anim)
	weapon_controller.visible = false

func exit():
	weapon_controller.visible = true
