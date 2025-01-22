class_name CurrentGame
extends Node

func player() -> Player:
	return get_node_or_null("Player") as Player

func _ready() -> void:
	Global.set_mouse_visibility(false)
