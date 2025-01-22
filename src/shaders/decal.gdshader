//https://github.com/Master-J/DecalCo
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, depth_test_disabled;

uniform sampler2D border_mask : hint_default_white;

uniform sampler2D albedo : source_color;
uniform vec4 albedo_tint : source_color = vec4(1.0);

uniform sampler2D emission : hint_default_black;
uniform vec4 emission_tint : source_color = vec4(vec3(0.0), 1.0);
uniform float emission_strength = 1.0;

uniform sampler2D occlusion : hint_default_white;
uniform float occlusion_strength = 1.0;

varying vec3 decal_half_scale;
varying vec3 decal_right;
varying vec3 decal_up;
varying vec3 decal_forward;

uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;
varying vec3 frag_to_light;

//Checks if the given point is in the decal's boundaries using an oriented bounding box defined by the decal's tranform
bool is_point_in_decal_bounds(vec3 point, vec3 decal_position)
{
	vec3 scale = decal_half_scale * 2.0;
	vec3 p = point - decal_position;
	return abs(dot(p, decal_right)) <= scale.x && abs(dot(p, decal_forward)) <= scale.y && abs(dot(p, decal_up)) <= scale.z;
}

void vertex()
{
	vec3 world_position = (MODEL_MATRIX*vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	UV = world_position.xy;
	UV2 = vec2(world_position.z,0.0);

	decal_right = (MODEL_MATRIX*vec4(1.0, 0.0, 0.0, 1.0)).xyz - world_position;
	decal_forward = (MODEL_MATRIX*vec4(0.0, 0.0, -1.0, 1.0)).xyz - world_position;
	decal_up = (MODEL_MATRIX*vec4(0.0, 1.0, 0.0, 1.0)).xyz - world_position;
	decal_half_scale = vec3(length(decal_right), length(decal_forward), length(decal_up)) / 2.0;
	decal_right = normalize(decal_right);
	decal_forward = normalize(decal_forward);
	decal_up = normalize(decal_up);

	//Override the projector mesh's normals in order to render the decal with mostly correct lighting
	NORMAL = vec3(0.0, 0.0, 1.0);
	TANGENT = vec3(1.0, 0.0, 0.0);
	BINORMAL = vec3(0.0, 1.0, 0.0);

}

void fragment ()
{
	//Compute world position using the depth buffer
	float depth = texture(depth_texture, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vec3 world_position = world.xyz / world.w;

	vec3 decal_position = vec3(UV.xy, UV2.x);


	if(is_point_in_decal_bounds(world_position, decal_position))
	{
		//If the world position is within the decal's boundaries, we can compute it's uv coordinates
		vec4 local_position = (vec4(world_position - decal_position, 0.0)) * MODEL_MATRIX;

		vec2 uv_coords = (vec2(local_position.x, -local_position.y)  / (4.0*(decal_half_scale.xz * 2.0 * decal_half_scale.xz))) - vec2(0.5);

		//This is used to fix some blending issues on the decal's edges, border mask is a white texture with a 1px transparent border on all sides
		float border_alpha = texture(border_mask, uv_coords).a;

		//Hacky stuff, to get UVs, correct lighting and normal mapping working, i need to get the fragment's local position in the light shader
		frag_to_light = vec3(1.0) - local_position.xyz / 100.0;

		ALBEDO = texture(albedo, uv_coords).rgb * albedo_tint.rgb;
		EMISSION = texture(emission, uv_coords).rgb * emission_tint.rgb * emission_strength;
		ALPHA = texture(albedo, uv_coords).a * albedo_tint.a * border_alpha;
	}else{
		ALPHA = 0.0;
	}
}

//taken from http://www.thetenthplanet.de/archives/1180
mat3 cotangent_frame(vec3 N, vec3 p, vec2 uv)
{

	vec3 dp1 = dFdx(p);
	vec3 dp2 = dFdy(p);
	vec2 duv1 = dFdx(uv);
	vec2 duv2 = dFdy(uv);

	vec3 dp2perp = cross( dp2, N );
	vec3 dp1perp = cross( N, dp1 );

	vec3 T = dp2perp * duv1.x + dp1perp * duv2.x;
	vec3 B = dp2perp * duv1.y + dp1perp * duv2.y;

	float invmax = inversesqrt( max( dot(T,T), dot(B,B) ) );
	return mat3( T * invmax, B * invmax, N );
}

void light ()
{
	//Get back the data from the fragment shader
	vec3 data = (vec3(1.0) - frag_to_light) * 100.0;

	//Recompute UV coordinates
	vec2 uv_coords = vec2(data.x, -data.y);

	uv_coords = (uv_coords.xy / (4.0*(decal_half_scale.xz * 2.0 * decal_half_scale.xz))) - vec2(0.5);

	//Normal mapping
	vec3 normal = NORMAL;

	float n_dot_l = clamp(dot(normal, LIGHT), 0.0, 1.0);

	//Diffuse lighting
	vec3 albedo_color = ALBEDO * n_dot_l;
	albedo_color = albedo_color * mix(1.0, texture(occlusion, uv_coords).r, occlusion_strength);

	DIFFUSE_LIGHT += albedo_color * ATTENUATION * LIGHT_COLOR;
}