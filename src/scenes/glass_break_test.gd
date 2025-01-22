extends Node

@onready var grid: GridContainer = $MarginContainer/GridContainer
@onready var glass_surface: MeshInstance3D = $GlassSurface

var supports := []
var recalc_supports := []
var bit_vec : PackedInt32Array 

const WIDTH = 20
const HEIGHT = 20
const MAX_HEIGHT = 20

var last_think_time := 0.0

func _ready() -> void:
	# Init visual
	grid.columns = WIDTH
	for i in WIDTH * HEIGHT:
		var pane = Button.new()
		#pane.text = str(i)
		#pane.add_theme_font_size_override("font_size", 8)
		pane.custom_minimum_size = Vector2i(10, 10)
		pane.pressed.connect(on_pane_pressed.bind(i))
		grid.add_child(pane)
	# Init data
	supports = []
	supports.resize(HEIGHT)
	recalc_supports = []
	recalc_supports.resize(HEIGHT)
	for i in HEIGHT:
		supports[i] = PackedFloat32Array()
		supports[i].resize(WIDTH)
		recalc_supports[i] = PackedFloat32Array()
		recalc_supports[i].resize(WIDTH)
		for j in WIDTH:
			supports[i][j] = 1.0
			recalc_supports[i][j] = 1.0
	bit_vec = PackedInt32Array()
	bit_vec.resize(MAX_HEIGHT)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("fire_2"):
		break_think()
	for i in WIDTH * HEIGHT:
		#grid.get_child(i).text = "%.2f" % (supports[i / WIDTH][i % WIDTH])
		if is_broken(i / WIDTH, i % WIDTH):
			grid.get_child(i).modulate = Color.DIM_GRAY
		else:
			grid.get_child(i).modulate = Color.RED.lerp(Color.GREEN, supports[i / WIDTH][i % WIDTH])
	glass_surface.material_override.set_shader_parameter("bit_vec", bit_vec)

func on_pane_pressed(pane_index : int):
	break_pane(pane_index / WIDTH, pane_index % WIDTH)
	break_think()

func break_pane(h : int, w : int):
	supports[h][w] = -1.0
	grid.get_child(h * WIDTH + w).disabled = true
	bit_vec[h] |= (1 << w);

func set_support(h : int, w : int, value : float):
	supports[h][w] = value

func get_support(h : int, w : int):
	return max(0, supports[h][w])

func recalc_support(h : int, w : int):
	var support = 0.01
	# Top support
	if h == 0:
		support += 1.0
	else:
		support += get_support(h-1, w)
	# Bottom support
	if h == HEIGHT-1:
		support += 1.25
	else:
		support += 1.25 * get_support(h+1, w)
	# Left support
	if w == 0:
		support += 1.0
	else:
		support += get_support(h, w-1)
	# Right support
	if w == WIDTH-1:
		support += 1.0
	else:
		support += get_support(h, w+1)
	# Bottom Left support
	if w == 0 || h == HEIGHT-1:
		support += 1.0
	else:
		support += get_support(h+1, w-1)
	# Bottom Right support
	if w == WIDTH-1 || h == HEIGHT-1:
		support += 1.0
	else:
		support += get_support(h+1, w+1)
	# Top Left support
	if w == 0 || h == 0:
		support += 0.25
	else:
		support += 0.25 * get_support(h-1, w-1)
	# Top Right support
	if w == WIDTH-1 || h == 0:
		support += 0.25
	else:
		support += 0.25 * get_support(h-1, w+1)
	return support

func is_broken(h : int, w : int):
	return supports[h][w] == -1.0

func break_think():
	for h in HEIGHT:
		for w in WIDTH:
			recalc_supports[h][w] = recalc_support(h, w)
	for h in HEIGHT:
		for w in WIDTH:
			if !is_broken(h, w):
				set_support(h, w, recalc_supports[h][w] / 6.75)
				if supports[h][w] < 0.2:
					break_pane(h, w)
	last_think_time = CustomTime.physics_time

func _physics_process(delta: float) -> void:
	if CustomTime.physics_time - last_think_time > 0.05:
		break_think()
