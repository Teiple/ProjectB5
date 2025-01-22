shader_type spatial;

render_mode unshaded, cull_disabled, blend_mix, depth_draw_opaque;
uniform sampler2D decal_texture : source_color, filter_linear, repeat_disable;
uniform sampler2D base_texture : source_color, filter_linear_mipmap, repeat_disable;
uniform int width = 10;
uniform int height = 10;
uniform int[20] bit_vec;
uniform float a = 0.0;

const vec2 TOP_LEFT = vec2(0.0, 0.0);
const vec2 TOP = vec2(0.33, 0.0);
const vec2 TOP_RIGHT = vec2(0.67, 0.0);
const vec2 LEFT = vec2(0.0, 0.33);
const vec2 RIGHT = vec2(0.67, 0.33);
const vec2 BOTTOM_LEFT = vec2(0.0, 0.67);
const vec2 BOTTOM = vec2(0.33, 0.67);
const vec2 BOTTOM_RIGHT = vec2(0.67, 0.67);

void vertex() {
	// Called for every vertex the material is visible on.
}

float is_broken(int w_idx, int h_idx){
	if (w_idx < 0 || w_idx >= width){
		return 0.0;
	}
	if (h_idx < 0 || h_idx >= height){
		return 0.0;
	}
	return float(bit_vec[h_idx] & (1 << w_idx));
}

vec2 rotateUV(vec2 uv, vec2 pivot, float rotation) {
    float sine = sin(rotation);
    float cosine = cos(rotation);
    vec2 rotated_uv = uv;

    uv -= pivot;
    rotated_uv.x = uv.x * cosine - uv.y * sine;
    rotated_uv.y = uv.x * sine + uv.y * cosine;
    rotated_uv += pivot;

    return rotated_uv;
}

float random (vec2 uv) {
    return fract(sin(dot(uv.xy,
        vec2(12.9898,78.233))) * 43758.5453123);
}

float sample_patch(vec2 patch, vec2 uv, int pane_w, int pane_h) {
    float rotation = (random(vec2(float(pane_w), float(pane_h))) * 2.0 - 1.0) * PI;

    vec2 uv_pivot = vec2(0.3, 0.3);
    vec2 decal_uv = patch + uv / 3.0;
	decal_uv = rotateUV(decal_uv, vec2(0.5), rotation);

    return texture(decal_texture, decal_uv).r;
}
void fragment() {
	float d_w = 1.0 / float(width);
	float d_h = 1.0 / float(height);
	int w_idx = int(UV.x / d_w);
	int h_idx = int(UV.y / d_h);
	vec2 uv_pivot = vec2(d_w * float(w_idx), d_h * float(h_idx));
	vec2 uv = vec2(clamp((UV.x - uv_pivot.x) / d_w, 0.0, 1.0), clamp((UV.y - uv_pivot.y) / d_h, 0.0, 1.0));

	vec4 albedo_tex = texture(base_texture, UV);
	ALBEDO = albedo_tex.rgb;

	float r = random(uv);

	// Calculate alpha values based on neighboring cells and their 'broken' status
	float alpha_self =1.0 - is_broken(w_idx, h_idx);
	float alpha_tl =1.0 - is_broken(w_idx+1, h_idx+1) * sample_patch(TOP_LEFT, uv, w_idx+1, h_idx+1);
	float alpha_t =  1.0 -is_broken(w_idx, h_idx+1) * sample_patch(TOP, uv, w_idx, h_idx+1);
	float alpha_tr = 1.0 -is_broken(w_idx-1, h_idx+1) * sample_patch(TOP_RIGHT, uv, w_idx-1, h_idx+1);
	float alpha_l =1.0 - is_broken(w_idx+1, h_idx) * sample_patch(LEFT, uv, w_idx+1, h_idx);
	float alpha_r = 1.0 -is_broken(w_idx-1, h_idx) * sample_patch(RIGHT, uv, w_idx-1, h_idx);
	float alpha_bl =1.0 - is_broken(w_idx+1, h_idx-1) * sample_patch(BOTTOM_LEFT, uv, w_idx+1, h_idx-1);
	float alpha_b = 1.0 - is_broken(w_idx, h_idx-1) * sample_patch(BOTTOM, uv, w_idx, h_idx-1);
	float alpha_br =1.0 - is_broken(w_idx-1, h_idx-1) * sample_patch(BOTTOM_RIGHT, uv, w_idx-1, h_idx-1);

	// Calculate the minimum alpha across all cells
	float min_alpha = min(
		alpha_self,
		min(alpha_tl, min(alpha_t, min(alpha_tr, min(alpha_l, min(alpha_r, min(alpha_bl, min(alpha_b, alpha_br)))))))
	);

	// Apply the final alpha value
	ALPHA = min_alpha;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
