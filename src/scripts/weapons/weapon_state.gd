extends FSMState
class_name WeaponState

@onready var weapon : Weapon = owner.owner # first owner: WeaponStateMachine  -> second owner: Weapon (SMG, Handgun, Shotgun, etc.) 
