extends Node

@export_group("Player", "player_")
@export var player_third_person_view := false : set = toggle_player_third_person_view
@export var player_show_collision_shape := false : set = toggle_player_collision_shape
@export_group("General")
@export var show_zones := false : set = toggle_zones
@export var show_hitboxes := false : set = toggle_hitboxes
@export var show_melee_hitboxes := false : set = toggle_melee_hitboxes

func _ready():
	if Engine.has_singleton("Panku"):
		Engine.get_singleton("Panku").interactive_shell_visibility_changed.connect(_on_debug_console_visibility_changed)
	
func toggle_zones(enabled : bool):
	show_zones = enabled
	
	var nodes = get_tree().get_nodes_in_group(Groups.ZONE_GROUP)
	for i in nodes.size():
		var node := nodes[i] as Zone
		if node == null:
			continue
		node.toggle_debug_view(enabled)

func toggle_hitboxes(enabled : bool):
	show_hitboxes = enabled
	
	var nodes = get_tree().get_nodes_in_group(Groups.HITBOX_GROUP)
	for i in nodes.size():
		var node := nodes[i] as HitboxComponent
		if node == null:
			continue
		node.toggle_debug_view(enabled)

func toggle_melee_hitboxes(enabled : bool):
	show_melee_hitboxes = enabled
	
	var nodes = get_tree().get_nodes_in_group(Groups.MELEE_HITBOX_GROUP)
	for i in nodes.size():
		var node := nodes[i] as WeaponMeleeComponent 
		if node == null:
			continue
		node.toggle_debug_view(enabled)

func _on_debug_console_visibility_changed(visible : bool):
	if visible:
		Global.set_mouse_visibility(true)
	else:
		Global.set_mouse_visibility(false)

func toggle_player_third_person_view(enabled : bool):
	player_third_person_view = enabled
	Global.current_game().player().toggle_third_person_view(enabled)

func toggle_player_collision_shape(enabled : bool):
	player_show_collision_shape = enabled
	Global.current_game().player().toggle_collision_shape(enabled)
