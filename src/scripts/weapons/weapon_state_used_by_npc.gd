extends WeaponState

func enter(msg := {}):
	weapon.collision_layer = 0
	weapon.collision_mask = 0
	weapon.set("freeze", true)
	weapon.pickup_zone.set_enabled(false)
	weapon.set_material_for_view(false)
