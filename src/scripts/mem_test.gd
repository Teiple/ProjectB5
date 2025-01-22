extends Node

@onready var mem_label: Label = $MemLabel
#@export var long_str := "Hello sandjnsakdnkjanskdnklasdnklnklsdnnxm cmkowejdhndjndxc llwlkmndklad"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var mem_cur = Performance.get_monitor(Performance.MEMORY_STATIC)/1024.0/1024.0
	var mem_max = Performance.get_monitor(Performance.MEMORY_STATIC_MAX)/1024.0/1024.0
	mem_label.text = "Mem: %.4f\nMem Max: %.4f\n" % [mem_cur, mem_max]
