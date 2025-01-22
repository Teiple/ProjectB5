extends Control

signal loaded

@export_file("*.tscn", "*.scn") var scene_path := "res://"
@onready var progress_bar : ProgressBar = $MarginContainer/ProgressBar
var progress : Array[float]= []

func _ready():
	var err = ResourceLoader.load_threaded_request(scene_path)

func _process(delta):
	var loading_status := ResourceLoader.load_threaded_get_status(scene_path, progress)
	# For some reasons, the returned won't be THREAD_LOAD_INVALID_RESOURCE,
	# even if the path is invalid
	match loading_status:
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_INVALID_RESOURCE:
			print_debug("Invalid path!")
			set_process(false)
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_IN_PROGRESS:
			var percentage = progress[0] * 100.0 
			progress_bar.value = percentage
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED:
			print_debug("Failed!")
			set_process(false)
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
			progress_bar.value = 100.0
			print_debug("Loaded!")
			loaded.emit()
			set_process(false)
