shader_type spatial;
render_mode unshaded, shadows_disabled, depth_draw_opaque, cull_back, blend_mix;
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform vec3 uv1_scale = vec3(1, 1, 1);
uniform vec3 uv1_offset;
uniform vec3 uv2_scale = vec3(1, 1, 1);
uniform vec3 uv2_offset;

void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;

	// Code from Polysthetic (Youtube)
	vec3 cam_origin = MAIN_CAM_INV_VIEW_MATRIX[3].xyz;
	vec3 spr_origin = MODEL_MATRIX[3].xyz;
	
	vec3 basis_y = MODEL_MATRIX[1].xyz;
	// Universal scaling for partical system
	float scale = length(basis_y);
	// Make the quad face the camera's plane instead of the camera itself for better performance
	//vec3 basis_z = MAIN_CAM_INV_VIEW_MATRIX[2].xyz;
	vec3 basis_z = normalize(cam_origin - spr_origin) * scale;
	
	vec3 basis_x = normalize(cross(basis_y, basis_z)) * scale;

	mat4 new_mat = MODEL_MATRIX;
	new_mat[0].xyz = basis_x;
	new_mat[2].xyz = basis_z;

	MODELVIEW_MATRIX = VIEW_MATRIX * new_mat;
}

void fragment() {
	vec2 base_uv = UV;

	vec4 albedo_tex = texture(texture_albedo, base_uv);
	albedo_tex *= COLOR;
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	ALPHA = albedo.a * albedo_tex.a;
}
