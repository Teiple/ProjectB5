extends Control
class_name HUD

@onready var ammo_counter := $AmmoCounter
@onready var health := $Health

@onready var debug_label := $DebugLabel
@onready var fps_monitor_label: Label = $FPSMonitorLabel

var player : Player = null

func _ready():
	player = Global.current_game().player()
	if !player.is_node_ready():
		await player.ready
	
	var player_health_component := Component.find_component(player, "HealthComponent") as HealthComponent
	if player_health_component != null:
		player.health_component.damaged.connect(update_health)
		player.health_component.healed.connect(update_health)
		player.health_component.died.connect(update_health)
	
	if is_instance_valid(player.weapon_controller):
		player.weapon_controller.weapon_fired.connect(update_ammo_counter)
		player.weapon_controller.weapon_equipped.connect(update_ammo_counter)
		player.weapon_controller.weapon_changed.connect(update_ammo_counter)
		player.weapon_controller.weapon_reloaded.connect(update_ammo_counter)
	
	update_health(player.health_component)
	update_ammo_counter()

func update_ammo_counter():
	if !is_instance_valid(player.weapon_controller) || !player.weapon_controller.is_holding_weapon():
		ammo_counter.visible = false
	else:
		ammo_counter.visible = true
		ammo_counter.text = "[\'\'\'] %d/%d" % [player.weapon_controller.current_weapon.current_ammo, player.weapon_controller.get_reserve_ammo_for_current_weapon()]

func update_health(health_component : HealthComponent):
	if health_component == null:
		return
	var hp = ceili(player.health_component.current_health)
	var max_hp = ceili(player.health_component.max_health)
	health.text = "[ + ] %d/%d" % [hp, max_hp]

func _process(delta):
	update_debug_label()
	update_fps_monitor_label()

func update_debug_label():
	var info := ""
	# Player state:
	var player_current_state = Global.current_game().player().state_machine.get_current_state_path()
	info += "Player state: %s\n" % player_current_state
	# Weapon controller state:
	var weapon_controller = Global.current_game().player().weapon_controller
	if is_instance_valid(weapon_controller):
		var weapon_controller_current_state = weapon_controller.state_machine.get_current_state_path()
		info += "Weapon controller state: %s\n" % weapon_controller_current_state
		# Current weapon:
		if weapon_controller.current_weapon != null: 
			var current_weapon_current_state = weapon_controller.current_weapon.state_machine.get_current_state_path()
			info += "Current weapon state: %s\n" % current_weapon_current_state
	
	# Pools:
	var pools = get_tree().get_nodes_in_group("pools")
	for i in pools.size():
		var pool = pools[i] as Pool
		if pool == null:
			continue
		info += pool.get_info()
	
	# Performance:
	var mem_cur = Performance.get_monitor(Performance.MEMORY_STATIC)/(1024.0*1024.0)
	var mem_max = Performance.get_monitor(Performance.MEMORY_STATIC_MAX)/(1024.0*1024.0)
	info += "Mem Static Current: %.4f\n Mem Static Max: %.4f" % [mem_cur, mem_max]
	
	debug_label.text = info

func update_fps_monitor_label():
	var fps = Performance.get_monitor(Performance.TIME_FPS) 
	const FPS_GOOD = 40
	const FPS_MEDIUM = 20
	const FPS_BAD = 0
	var fps_colors = {"Good" : Color.GREEN, "Medium" : Color.YELLOW, "Bad" : Color.RED}
	if fps >= FPS_GOOD:
		fps_monitor_label.modulate = fps_colors["Good"]
	elif fps >= FPS_MEDIUM:
		fps_monitor_label.modulate = fps_colors["Medium"]
	elif fps >= FPS_BAD:
		fps_monitor_label.modulate = fps_colors["Bad"]
	else:
		fps_monitor_label.modulate = Color.WHITE
	fps_monitor_label.text = str(fps)
