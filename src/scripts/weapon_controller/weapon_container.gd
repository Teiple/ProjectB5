extends Node3D
# This is an effort to solve this run-time error of Godot Jolt:
# E 0:02:50:0669   try_build_shape: Godot Jolt failed to scale body 'PickupZone:<Area3D#114823268456>'. (0.999997, 0.999926, 0.999924) is not a valid scale for the types of shapes in this body. Its scale will instead be treated as (1, 1, 1).
#  <C++ Source>   src\objects\jolt_shaped_object_impl_3d.cpp:141 @ try_build_shape()
# The error may be caused by the fact the imported skeletion has non-uniformed scale

func _ready():
	global_transform = global_transform.orthonormalized()
