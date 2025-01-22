@tool
extends Control
class_name VolumeBarSlider

signal value_changed(new_value)

@export var bar_height_curve : Curve = null
@export var volumn_bar_min_height := 8
@export var volumn_bar_enabled_color := Color.GOLD
@export var volumn_bar_disabled_color := Color.GRAY
@export var volumn_bar_spacing := 2
@export var clear_bars := false :
	set(val):
		# Don't run this when opening the scene 
		# And also don't run this in other scene
		if Engine.is_editor_hint() && is_node_ready() \
		&& EditorInterface.get_edited_scene_root() is VolumeBarSlider:
			clear()
@export var recreate := false :
	set(val):
		# Don't run this when opening the scene 
		# And also don't run this in other scene
		if Engine.is_editor_hint() && is_node_ready() \
		&& EditorInterface.get_edited_scene_root() is VolumeBarSlider:
			create()
@export var volumn_bar_scene : PackedScene 
@export	var volumn_bar_count := 12

@export_range(0.0, 1.0, 0.001) var value := 0.1 :
	set = set_value, get = get_value

@onready var bars : Control = $Bars
@onready var increase_button : TextureButton = %IncreaseButton
@onready var decrease_button : TextureButton = %DecreaseButton

func clear():
	for i in bars.get_child_count():
		bars.get_child(i).queue_free()

func create():
	clear()
	#bars.size = size
	#bars.position = Vector2i.ZERO
	for i in volumn_bar_count:
		var bar := volumn_bar_scene.instantiate() as Control
		bars.add_child(bar, true)
		bar.owner = self
		
		set_bar(bar, i)

func resize():
	#bars.size = size
	#bars.position = Vector2.ZERO
	for i in volumn_bar_count:
		if i >= bars.get_child_count():
			break
		var bar = bars.get_child(i)
		
		set_bar(bar, i)

func set_bar(bar : Control, index : int):
	var volumn_bar_base_width = bars.size.x / volumn_bar_count
	var volumn_bar_max_height = bars.size.y
	
	bar.size.x = volumn_bar_base_width - volumn_bar_spacing
	bar.size.y = clampi(int(bar_height_curve.sample((index+1.0)/volumn_bar_count) * volumn_bar_max_height),
	volumn_bar_min_height, volumn_bar_max_height)
	
	bar.position.x = index * volumn_bar_base_width
	bar.position.y = -bar.size.y + bars.size.y
	
	bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	
	var value_in_bars = roundi(value * volumn_bar_count)
	bar.modulate = volumn_bar_enabled_color if (index + 1) <= value_in_bars else volumn_bar_disabled_color

func on_increase_button_pressed():
	var step = 1.0 / volumn_bar_count
	set_value(value + step)
	snap_value()

func on_decrease_button_pressed():
	var step = 1.0 / volumn_bar_count
	set_value(value - step)
	snap_value()

func set_value(val):
	value = clampf(val, 0.0, 1.0)
	value_changed.emit(val)
	if !is_node_ready():
		await ready
	var value_in_bars = roundi(value * volumn_bar_count)
	
	for i in volumn_bar_count:
		if i >= bars.get_child_count():
			break
		var bar : Control = bars.get_child(i)
		if i+1<= value_in_bars:
			bar.modulate = volumn_bar_enabled_color
		else:
			bar.modulate = volumn_bar_disabled_color

func get_value():
	return value

func snap_value():
	var value_in_bars = roundi(value * volumn_bar_count)
	value = 1.0 * value_in_bars / volumn_bar_count

func _on_bars_item_rect_changed():
	if !is_node_ready():
		await ready
	resize()

func mouse_evaluate(mouse_position : Vector2):
	var chosen_value = 1.0 * mouse_position.x / bars.size.x
	set_value(chosen_value)

# Only run in-game
func _on_bars_gui_input(event : InputEvent):
	if event is InputEventMouseButton:
		if event.is_pressed() && event.button_index == MOUSE_BUTTON_LEFT:
			# event.position is in local position of bar container
			mouse_evaluate(event.position)
	elif event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			mouse_evaluate(event.position)
