// NOTE: Shader automatically converted from Godot Engine 4.3.beta2's StandardMaterial3D.

shader_type spatial;
render_mode cull_back, unshaded, depth_draw_opaque, shadows_disabled;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

uniform sampler2D strength_curve;
uniform float rope_length = 10.0;
uniform float rope_max_amplitude = 0.5;
uniform float time_scale = 5.0;
uniform float frequency = 1.0;
uniform float y_scale = 1.0;

void vertex() {
	float vertex_y_global = VERTEX.y * y_scale;
	float movement = sin(frequency * (vertex_y_global + TIME*time_scale)) * rope_max_amplitude;
	float amplitude = texture(strength_curve, vec2(VERTEX.y / rope_length, 0.0)).g;
	VERTEX.x += movement * amplitude;

	// Stretched Billboard
	// Code from Polysthetic (Youtube)
	vec3 cam_origin = MAIN_CAM_INV_VIEW_MATRIX[3].xyz;
	vec3 spr_origin = MODEL_MATRIX[3].xyz;

	// Make the quad face the camera's plane instead of the camera itself for better performance
	vec3 basis_z = normalize(cam_origin - spr_origin);
	vec3 basis_y = MODEL_MATRIX[1].xyz;
	vec3 basis_x = normalize(cross(basis_y, basis_z));

	mat4 new_mat = MODEL_MATRIX;
	new_mat[0].xyz = basis_x;
	new_mat[2].xyz = basis_z;

	MODELVIEW_MATRIX = VIEW_MATRIX * new_mat;
}

void fragment() {
	vec2 base_uv = UV;

	vec4 albedo_tex = texture(texture_albedo, base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
}
