extends Setting
class_name SettingSlider

@export var slider_max_value := 100.0
@export var slider_step := 5.0
@export var use_percentage := false

@onready var slider: HSlider = %Slider
@onready var value_label: Label = %ValueLabel

func _ready():
	if !slider.is_node_ready():
		await slider.ready
	slider.max_value = slider_max_value
	slider.step = slider_step
	super._ready()

func get_current_value() -> Variant:
	return slider.value

func set_current_value(value):
	slider.value = value
	set_value_label_text(value)

func _on_slider_value_changed(value: float) -> void:
	set_value_label_text(value)

func set_value_label_text(value : float):
	if int(value) == value && int(slider.step) == slider.step: # Integer mode
		value_label.text = "%d" % int(value)
	else: # Float mode
		value_label.text = "%.2f" % value
	if use_percentage:
		value_label.text += "%"
