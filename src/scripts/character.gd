extends CharacterBody3D
class_name Character

var _health_component : HealthComponent = null
var _hitbox_components : Array = [] # Cannot do element type hint since it cannot be auto casted

func _ready():
	_health_component = Component.find_component(self, HealthComponent.get_component_name())
	_hitbox_components = Component.find_component_array(self, HitboxComponent.get_component_name())

func get_health_component() -> HealthComponent:
	return _health_component

func get_hitbox_components() -> Array:
	return _hitbox_components
