extends RigidBody3D
class_name PhysicsObject

@onready var sounds: Node3D = $Sounds
@export var hard_impact_speed_threshold := 2.0
@export var average_velocity_tracker_duration := 0.2
@export var scrape_sfx := true

var average_velocity_tracker : Array[Vector3] = []
var average_velocity_tracker_capacity := 10
var average_velocity_lasted_tracked_time := -100.0

var average_velocity := Vector3.ZERO

func _ready():
	var health_component = health_component()
	health_component.damaged.connect(_on_damaged)

func health_component() -> HealthComponent:
	return Component.find_component(self, HealthComponent.get_component_name()) as HealthComponent

func _on_damaged(health_component : HealthComponent):
	if health_component == null:
		return
	var attack_info = health_component.last_attack_info
	apply_impulse(attack_info.knock_back_vector, attack_info.hit_point - global_position)
	if attack_info.attack_type == AttackInfo.AttackType.BULLET:
		find_sound_node_and_play("ImpactBullet")
	elif attack_info.attack_type == AttackInfo.AttackType.MELEE:
		find_sound_node_and_play("ImpactHard")

func _on_body_entered(body: Node) -> void:
	var speed_sqr = linear_velocity.length_squared()
	if speed_sqr >= hard_impact_speed_threshold*hard_impact_speed_threshold:
		find_sound_node_and_play("ImpactHard")
	else:
		find_sound_node_and_play("ImpactSoft")

func find_sound_node_and_play(node_name : String):
	var s : AudioStreamPlayer3D = sounds.get_node_or_null(node_name) as AudioStreamPlayer3D
	if s != null:
		s.play()

func find_sound_node(node_name : String) -> AudioStreamPlayer3D:
	var s : AudioStreamPlayer3D = sounds.get_node_or_null(node_name) as AudioStreamPlayer3D
	return s

func _physics_process(delta: float) -> void:
	average_velocity_tracker.push_back(linear_velocity)
	average_velocity = get_average_velocity()
	
	var contact_count = get_contact_count()
	var scrape = find_sound_node("Scrape")
	if scrape_sfx && contact_count >= 4:
		if average_velocity.length_squared() > 1.0:
			scrape.volume_db = linear_to_db(lerpf(db_to_linear(scrape.volume_db), 1.0, 5.0 * delta))
			if !scrape.is_playing():
				scrape.play()
		else:
			scrape.volume_db = linear_to_db(lerpf(db_to_linear(scrape.volume_db), 0.0, 5.0 * delta))
	else:
		scrape.volume_db = linear_to_db(lerpf(db_to_linear(scrape.volume_db), 0.0, 5.0 * delta))
	

func get_average_velocity() -> Vector3:
	if average_velocity_tracker.size() == average_velocity_tracker_capacity + 1:
		average_velocity_tracker.pop_front()
	var sum_vec = Vector3.ZERO
	for i in average_velocity_tracker.size():
		sum_vec += average_velocity_tracker[i]
	var avg = sum_vec /  average_velocity_tracker.size()
	average_velocity_tracker.pop_front()
	return avg
