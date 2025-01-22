
# Based on https://gist.github.com/ViniciusMeirelles/7ef55b9bfec7f3b5e3448b1a7a63b5ef
@tool
extends Node3D

signal compiled

@export var cache_scene_btn := false:
	set(val):
		if !Engine.is_editor_hint():
			return
		cache_scene(val)
@export var clear_cache_btn := false:
	set(val):
		if !Engine.is_editor_hint():
			return
		clear_cache(val)

@export var active := true:
	set = set_active
@export_file("*.tscn", "*.scn") var scene_path := ""
## Cache every PackedScene from script variable
@export var cache_packed_scene_recusively := true
## Cache every unique materials from animation key
@export var cache_material_in_animation_player := true
@export var active_frame_count = 2

var local_to_scene_materials_node : Node3D
var materials_node : Node3D
var particles_materials_node : Node3D
var skeleton_node : Node3D

var _virtual_tree : Node
var _frame_countdown := 0
var _quad_mesh : QuadMesh
var _multi_mesh : MultiMesh
var _materials : Array[Material] = []
var _particles_materials : Dictionary = {}
var _meshes : Dictionary = {}

func _ready():
	if Engine.is_editor_hint():
		return
	# Set this node to be infront of the main camera
	position.z = -100.0
	set_active(active)
	if !active:
		push_warning("This ShaderCache node is in the scene but is not active. For production, please remember to enable all ShaderCache nodes.")

func _process(delta):
	if Engine.is_editor_hint():
		return
	
	if _frame_countdown > 0:
		_frame_countdown -= 1
	else:
		compiled.emit()
		set_active(false)

func emit_particles():
	particles_materials_node = get_particles_materials_node()
	if particles_materials_node:
		for particles in particles_materials_node.get_children():
			particles.emitting = true

func cache_scene(value=true):
	clear_cache()
	
	_virtual_tree = Node.new()
	_quad_mesh = QuadMesh.new()
	_multi_mesh = MultiMesh.new()
	_multi_mesh.mesh = _quad_mesh
	_multi_mesh.instance_count = 1
	
	var packed_scene := load(scene_path) as PackedScene
	_cache_scene(packed_scene)
	local_to_scene_materials_node = get_local_to_scene_materials_node()
	if local_to_scene_materials_node:
		print_debug("ShaderCache: Local to scene materials found(%d), " % local_to_scene_materials_node.get_child_count() + 
		"hover on children of `LocalToSceneMaterials` to check their origin or read from editor_description" )
	
	# Calculate the AABB of all the meshes
	if local_to_scene_materials_node:
		for i in local_to_scene_materials_node.get_child_count():
			var mesh := local_to_scene_materials_node.get_child(i) as MeshInstance3D
			var bounding_box = mesh.get_aabb()
			mesh.global_position -= bounding_box.get_center()
	if skeleton_node:
		for i in skeleton_node.get_child_count():
			var mesh := skeleton_node.get_child(i) as MeshInstance3D
			var bounding_box = mesh.get_aabb()
			mesh.global_position -= bounding_box.get_center()
	if materials_node:
		for i in materials_node.get_child_count():
			var mesh := materials_node.get_child(i) as MeshInstance3D
			var bounding_box = mesh.get_aabb()
			mesh.global_position -= bounding_box.get_center()
	
	_virtual_tree.queue_free()
	_materials.clear()
	_particles_materials.clear()

func clear_cache(value=true):
	_materials.clear()
	_particles_materials.clear()
	_meshes.clear()
	var to_free = []
	to_free.append(get_node_or_null("LocalToSceneMaterials"))
	to_free.append(get_node_or_null("Materials"))
	to_free.append(get_node_or_null("ParticlesMaterials"))
	to_free.append(get_node_or_null("Skeleton"))
	for node in to_free:
		if node == null:
			continue

		node.free()

func _cache_scene(packed_scene : PackedScene):
	var scene = packed_scene.instantiate()
	_virtual_tree.add_child(scene)
	_cache_node(scene, {"owner_path": packed_scene.resource_path})
	scene.queue_free()

func _cache_node(node : Node, extra:={}):
	if cache_packed_scene_recusively:
		for property in node.get_property_list():
			if property["type"] == TYPE_OBJECT and property["usage"] & (PROPERTY_USAGE_EDITOR + PROPERTY_USAGE_SCRIPT_VARIABLE): # Only check the exported script variables 
				var property_value = node.get(property["name"])
				# Dynamic scene creations
				if property_value is PackedScene:
					print_debug("In-game scene creations found in " + str(_virtual_tree.get_path_to(node)))
					_cache_scene(property_value)
					continue
				# Dynamic material changes
				if property_value is Material:
					print_debug("In-game material changes found in " + str(_virtual_tree.get_path_to(node)))
					if node.has_method("shader_cache_fetch_material_meshes"):
						# One material may be supposed to set for many meshes in-game 
						var meshes_instances := node.shader_cache_fetch_material_meshes(property["name"]) as Array[MeshInstance3D]
						for mesh_instance in meshes_instances:
							_cache_material(mesh_instance, property_value)
					continue
	
	if node is AnimationPlayer and cache_material_in_animation_player:
		var animation_player_node := node as AnimationPlayer
		var anim_player_root_node = animation_player_node.get_node(animation_player_node.root_node)
		for animation_name in animation_player_node.get_animation_list():
			var animation = animation_player_node.get_animation(animation_name)
			for track_idx in animation.get_track_count():
				for key_idx in animation.track_get_key_count(track_idx):
					var key_value = animation.track_get_key_value(track_idx, key_idx)
					if key_value is Material:
						var node_and_resource = anim_player_root_node.get_node_and_resource(animation.track_get_path(track_idx))
						_cache_material(node_and_resource[0], key_value, extra)
	
	if node is GeometryInstance3D:
		var geomery_instance_node := node as GeometryInstance3D
		if geomery_instance_node.material_override != null:
			var material = geomery_instance_node.material_override
			_cache_material(geomery_instance_node, material, extra)
		
		if geomery_instance_node.material_overlay != null:
			var material = geomery_instance_node.material_overlay
			_cache_material(geomery_instance_node, material, extra)
		
		if geomery_instance_node is MeshInstance3D:
			if geomery_instance_node.get_surface_override_material_count() > 0:
				for i in geomery_instance_node.get_surface_override_material_count():
					var material = geomery_instance_node.get_surface_override_material(i)
					_cache_material(geomery_instance_node, material, extra)
			
			if geomery_instance_node.mesh:
				for i in geomery_instance_node.mesh.get_surface_count():
					var material = geomery_instance_node.mesh.surface_get_material(i)
					_cache_material(geomery_instance_node, material, extra)
		
		if node is CSGPrimitive3D:
			var csg_primitive_node := node as CSGPrimitive3D
			if "material" in csg_primitive_node:
				var material = csg_primitive_node.get_material()
				_cache_material(csg_primitive_node, material, extra)
	
	if node is GPUParticles3D:
		var particles := node as GPUParticles3D
		if particles.process_material != null:
			var material = particles.material_override
			var proc_mat = particles.process_material
			_cache_particle_material(particles, material, proc_mat, extra)
	
	for child in node.get_children():
		if node.get_script():
			if node.get_script().get_path() == get_script().get_path(): # Ignore ShaderCache (this script)
				continue
		
		if is_instance_valid(child):
			_cache_node(child, extra)

func _cache_material(node : Node, material : Material, extra:={}):
	if not material:
		return

	if not _materials.has(material):
		_materials.append(material)
	else:
		return

	var geometry_instance : GeometryInstance3D
	if node is MultiMeshInstance3D:
		geometry_instance = new_multi_mesh_instance(node, material)
	elif node is GeometryInstance3D:
		geometry_instance = new_mesh_instance(node, material)
	
	if geometry_instance:
		var parent : Node
		if node.get_parent() is Skeleton3D:
			parent = get_skeleton_node(true)
		else:
			if material.resource_local_to_scene:
				# This code will fail as node.get_path() only work in in-game SceneTree!
				var from_node_path_string = String(node.get_path()).lstrip("/root/")
				var from_node_owner_path = extra.get("owner_path")
				parent = get_local_to_scene_materials_node(true)
				geometry_instance.editor_description = "Owner: %s\nNodePath: %s" % [from_node_owner_path, from_node_path_string]
			else:
				parent = get_materials_node(true)
		if parent:
			parent.add_child(geometry_instance)
			geometry_instance.set_owner(self)

# Add the process material and the material from particles
func _cache_particle_material(node : Node, material : Material, proc_mat : ParticleProcessMaterial, extra:={}):
	var draw_passes_list = _particles_materials.get(proc_mat)
	if draw_passes_list:
		# Ignore material if already loaded, taking both process material and draw passes into consideration
		for draw_passes in draw_passes_list:
			if draw_passes.size() == node.draw_passes:
				var is_cached = true
				for i in draw_passes.size():
					var node_draw_pass = node.get_draw_pass_mesh(i)
					var draw_pass = draw_passes[i]
					is_cached = is_cached and draw_pass == node_draw_pass
				if is_cached:
					return
	else:
		draw_passes_list = []
		_particles_materials[proc_mat] = draw_passes_list
	
	if node.preprocess > 0:
		var from_node_path_string = _virtual_tree.get_path_to(node) #String(node.get_path()).lstrip("/root/")
		var from_node_owner_path = extra.get("owner_path")
		print("ShaderCache: Particles with preprocess > 0 will not be cached properly, please set preprocess to 0. ", 
		"Owner: %s, NodePath: %s" % [from_node_owner_path, from_node_path_string]
		)

	var draw_passes = []
	for i in node.draw_passes:
		draw_passes.append(node.get_draw_pass_mesh(i))
	draw_passes_list.append(draw_passes)
	var particles = new_particles(node, material, proc_mat)
	get_particles_materials_node(true).add_child(particles)
	particles.set_owner(self)

# Create mesh instance for any class inherited from GeometryInstance
func new_mesh_instance(node : Node, material : Material):
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = _quad_mesh
	if "mesh" in node:
		if node.mesh is ArrayMesh: # MeshInstance must use original mesh if it is ArrayMesh
			var mesh = node.mesh
			var is_cached = true
			# Ignore array mesh if already loaded, taking both array mesh and materials into consideration
			if mesh in _meshes:
				var material_list = _meshes[mesh]
				if not material_list.has(material):
					material_list.append(material)
					is_cached = false
			else:
				_meshes[mesh] = [material]
				is_cached = false
			
			if not is_cached:
				mesh_instance.mesh = node.mesh
	mesh_instance.material_override = material
	mesh_instance.name = node.name
	mesh_instance.cast_shadow = node.cast_shadow
	return mesh_instance

func new_multi_mesh_instance(node, material):
	var multimesh = MultiMeshInstance3D.new()
	multimesh.multimesh = _multi_mesh
	multimesh.material_override = material
	multimesh.name = node.name
	multimesh.cast_shadow = node.cast_shadow
	return multimesh

func new_particles(node, material, proc_mat):
	var particles = GPUParticles3D.new()
	particles.lifetime = 0.1
	particles.one_shot = true
	particles.emitting = false
	particles.draw_passes = node.draw_passes
	for i in node.draw_passes:
		particles.set_draw_pass_mesh(i, node.get_draw_pass_mesh(i))
	particles.process_material = proc_mat
	particles.name = node.name
	particles.cast_shadow = node.cast_shadow
	particles.material_override = material
	return particles

func set_active(v):
	active = v
	visible = active
	if Engine.is_editor_hint():
		return
	
	set_process(active)
	if active:
		_frame_countdown = active_frame_count
		emit_particles()

func get_local_to_scene_materials_node(create_if_null=false):
	if not is_instance_valid(local_to_scene_materials_node):
		local_to_scene_materials_node = get_node_or_null("LocalToSceneMaterials")
		if not local_to_scene_materials_node and create_if_null:
			local_to_scene_materials_node = Node3D.new()
			local_to_scene_materials_node.name = "LocalToSceneMaterials"
			add_child(local_to_scene_materials_node)
			move_child(local_to_scene_materials_node, 0)
			local_to_scene_materials_node.owner = self
	return local_to_scene_materials_node

func get_materials_node(create_if_null=false):
	if not is_instance_valid(materials_node):
		materials_node = get_node_or_null("Materials")
		if not materials_node and create_if_null:
			materials_node = Node3D.new()
			materials_node.name = "Materials"
			add_child(materials_node)
			move_child(materials_node, int(min(get_child_count(), 1)))
			materials_node.owner = self
	return materials_node

func get_particles_materials_node(create_if_null=false):
	if not is_instance_valid(particles_materials_node):
		particles_materials_node = get_node_or_null("ParticlesMaterials")
		if not particles_materials_node and create_if_null:
			particles_materials_node = Node3D.new()
			particles_materials_node.name = "ParticlesMaterials"
			add_child(particles_materials_node)
			move_child(particles_materials_node, int(min(get_child_count(), 2)))
			particles_materials_node.owner = self
	return particles_materials_node

func get_skeleton_node(create_if_null=false):
	if not is_instance_valid(skeleton_node):
		skeleton_node = get_node_or_null("Skeleton")
		if not skeleton_node and create_if_null:
			skeleton_node = Skeleton3D.new()
			skeleton_node.name = "Skeleton"
			add_child(skeleton_node)
			move_child(skeleton_node, int(min(get_child_count(), 3)))
			skeleton_node.owner = self
	return skeleton_node
