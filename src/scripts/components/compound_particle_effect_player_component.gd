@tool
extends Component
class_name CompoundParticleEffectPlayerComponent

@export var _play := false :
	set=set_play

static func get_component_name() -> String:
	return "CompoundParticleEffectPlayerComponent"

func play_all():
	for effect in get_children():
		var gpu_particle_effect := effect as GPUParticles3D
		if gpu_particle_effect:
			gpu_particle_effect.restart()
			continue
		var cpu_particle_effect := effect as CPUParticles3D
		if cpu_particle_effect:
			cpu_particle_effect.restart()
			continue

func set_play(_play : bool):
	if _play == false:
		return
	if !Engine.is_editor_hint():
		return
	print_debug("Playing compound effect ...")
	play_all()
