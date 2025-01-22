extends WeaponState

func enter(msg := {}):
	weapon.play_action("idle")
	weapon.collision_layer = weapon.dropped_collision_layer
	weapon.collision_mask = weapon.dropped_collision_mask
	weapon.set("freeze", false)
	weapon.pickup_zone.set_enabled(true)
	weapon.set_material_for_view(false)
