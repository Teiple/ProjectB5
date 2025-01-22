extends Node3D
class_name CameraShaker

@export var max_land_shake_amount := 0.2
@export var max_land_shake_duration := 1.0
@export var land_shake_curve : Curve
@export var max_mantle_shake_amount : = -0.4
@export var max_mantle_shake_duration := 0.5
@export var mantle_shake_curve : Curve

@onready var player : Player = owner

func _ready():
	await player.ready
	player.land.connect(_on_player_landed)
	player.mantle_started.connect(_on_player_mantled)

func _on_player_landed(height : float):
	var tween = create_tween()
	tween.tween_method(shake_on_global_y.bind(land_shake_curve, max_land_shake_amount), 0.0, 1.0, max_land_shake_duration)

func _on_player_mantled(mantle_position : Vector3):
	var tween = create_tween()
	var height_difference = mantle_position.y - player.global_position.y
	var amount_multiplier = clampf(inverse_lerp(0.0, 0.4, height_difference), 0.0, 1.0)
	tween.tween_method(shake_x_rotation.bind(mantle_shake_curve, max_mantle_shake_amount), 0.0, 1.0, max_mantle_shake_duration * amount_multiplier)

func shake_on_global_y(offset : float, curve : Curve, amplitude : float):
	var offset_value = curve.sample(offset) * amplitude
	global_position = player.global_position
	global_position.y = player.head.global_position.y + offset_value

func shake_x_rotation(offset : float, curve : Curve, amplitude : float):
	var offset_value = curve.sample(offset) * amplitude
	rotation.x = offset_value
