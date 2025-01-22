extends Setting

@onready var volumn_bar_slider: VolumeBarSlider = $VolumnBarSlider

func _ready() -> void:
	# Await for the slider to set things up
	if !volumn_bar_slider.is_node_ready():
		await volumn_bar_slider.ready
	super._ready()

func set_current_value(value):
	volumn_bar_slider.set_value(value)

func get_current_value():
	return volumn_bar_slider.get_value()
