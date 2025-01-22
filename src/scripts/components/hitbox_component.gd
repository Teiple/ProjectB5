extends Component
class_name HitboxComponent

func _ready():
	super._ready()

static func get_component_name() -> String:
	return "HitboxComponent"

func receive_attack(attack_info : AttackInfo):
	if owner == null:
		return
	var health_component := Component.find_component(owner, "HealthComponent") as HealthComponent
	if health_component == null:
		return
	if health_component.is_dead:
		return
	health_component = health_component as HealthComponent
	health_component.take_damage(attack_info)
	
func toggle_debug_view(enabled : bool):
	var debug_collision_shapes_component := Component.find_component(self, DebugCollisionShapesComponent.get_component_name()) as DebugCollisionShapesComponent
	debug_collision_shapes_component.toggle_debug_view(enabled)

func get_character_owner() -> Character:
	return owner as Character

# Tricky way to bypass the casting error
func to_collision_object() -> CollisionObject3D:
	return get_node(".") as CollisionObject3D
