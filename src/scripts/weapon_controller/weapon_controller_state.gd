extends FSMState
class_name WeaponControllerState

@onready var weapon_controller : WeaponController = owner

func can_interrupt(interrupting_state : String) -> bool:
	return false
