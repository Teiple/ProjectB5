extends CharacterBody3D
class_name Character

var health_component : HealthComponent = null

func _ready():
	health_component = Component.find_component(self, "HealthComponent")
