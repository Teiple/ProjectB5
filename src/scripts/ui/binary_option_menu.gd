extends OptionButton
class_name BinaryOptionMenu

signal option_toggled(enabled: bool)

const DISABLED_ITEM_ID = 0
const ENABLED_ITEM_ID = 1

@export var enabled_by_default := false
@export var disabled_text := "Disabled"
@export var enabled_text := "Enabled"

func init_options():
	add_item(disabled_text, DISABLED_ITEM_ID)
	add_item(enabled_text, ENABLED_ITEM_ID)
	if enabled_by_default:
		selected = ENABLED_ITEM_ID
	else:
		selected = DISABLED_ITEM_ID

func _on_item_selected(index : int):
	if index == ENABLED_ITEM_ID:
		option_toggled.emit(true)
	else:
		option_toggled.emit(false)

func set_enabled(enabled : int):
	if enabled:
		selected = ENABLED_ITEM_ID
	else:
		selected = DISABLED_ITEM_ID

func get_enabled():
	return selected == ENABLED_ITEM_ID
