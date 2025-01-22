extends Component
class_name HealthComponent

signal damaged(component : HealthComponent)
signal died(component : HealthComponent)
signal healed(component : HealthComponent)

@export var invincible := false
@export var current_health : float = 100.0
@export var max_health : float = 100.0

@onready var character : Character

var last_attack_info : AttackInfo = null

var is_dead : bool = false

func _ready():
	super._ready()

static func get_component_name() -> String:
	return "HealthComponent"

func take_damage(attack_info : AttackInfo):
	if is_dead:
		return
	if !invincible:
		current_health -= attack_info.damage
	last_attack_info = attack_info
	if current_health <= 0.0:
		die()
		return
	damaged.emit(self)

func heal(amount : float):
	if current_health >= max_health:
		return
	current_health += amount
	if current_health > max_health:
		current_health = max_health
	healed.emit(self)

func die():
	is_dead = true
	died.emit(self)
