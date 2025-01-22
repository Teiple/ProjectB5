extends WeaponState

@onready var base_state : WeaponState = get_parent()

func enter(msg:={}):
	base_state.enter(msg)
