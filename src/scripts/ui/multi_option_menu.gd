extends OptionButton
class_name MultiOptionMenu

signal option_selected(option)

var options : Array[String] = []

func init_options(options_to_init : Array[String]):
	options = options_to_init
	for i in options.size():
		add_item(options[i], i)
	selected = 0

func set_option(option : String):
	var index = options.find(option)
	if index >= 0:
		selected = index

func get_option():
	return get_item_text(selected)

func _on_item_selected(index: int) -> void:
	var option = options[index]
	option_selected.emit(option)
