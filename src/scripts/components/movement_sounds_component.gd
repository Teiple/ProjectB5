extends Component
class_name MovementSoundsComponent

@export var land_heavy_height_threshold := 2.0 
## The number of automatic step signals before playing a footstep sound
@export var auto_step_threshold := 6

@onready var player : Player = owner
@onready var footsteps : AudioStreamPlayer = $Footsteps
@onready var jump_sounds : AudioStreamPlayer = $Jump
@onready var mantle_sounds : AudioStreamPlayer = $Mantle
@onready var land_soft_sounds : AudioStreamPlayer = $LandSoft
@onready var land_heavy_sounds : AudioStreamPlayer = $LandHeavy

var last_head_bob_x := 0.0
var last_cycle := 0
var continuous_auto_step_count := 0
var last_auto_step_time_mark := 0.0

func _ready():
	super._ready()
	await player.ready
	player.jump.connect(jump)
	player.mantle_started.connect(mantle)
	player.land.connect(land)
	player.step.connect(auto_step)

static func get_component_name()-> String:
	return "MovementSoundsComponent"

func _process(delta):
	step()

func auto_step():
	continuous_auto_step_count += 1
	last_auto_step_time_mark = CustomTime.time
	if continuous_auto_step_count >= auto_step_threshold:
		continuous_auto_step_count = 0
		footsteps.play()

func step():
	# The player won't create sounds while crouch walking
	if player.is_crouching():
		return
	# We don't want to auto step and normal step
	# to overlap each other
	if CustomTime.time - last_auto_step_time_mark <= 0.5:
		return
	last_head_bob_x = player.head.head_bob_x
	var cycle = int(player.head.head_bob_x / TAU)
	var x = player.head.head_bob_x - TAU * cycle
	if cycle > last_cycle && x >= 0.75 * PI:
		last_cycle = cycle
		footsteps.play()

func jump():
	jump_sounds.play()

func mantle(_mantle_position):
	mantle_sounds.play()

func land(height):
	if height < land_heavy_height_threshold:
		land_soft_sounds.play()
	else:
		land_heavy_sounds.play()
