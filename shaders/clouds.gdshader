shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back;
// The real clouds of one day (VIIRS true colour, 2024-08-31) as a layer above the surface; see
// assets/source/planet_textures.py. They drift slowly; the surface shader moves their shadows with them.
uniform sampler2D cloud_tex : filter_linear_mipmap, repeat_enable;
uniform float cloud_shift = 0.0;
uniform vec3 sun_dir = vec3(0.0, 0.0, 1.0);
void fragment() {
	float a = texture(cloud_tex, UV + vec2(cloud_shift, 0.0)).r;
	vec3 sv = normalize((VIEW_MATRIX * vec4(sun_dir, 0.0)).xyz);
	float ndl = dot(NORMAL, sv);
	// the edge of the day reddens the clouds a little, as at sunset
	float dusk = smoothstep(0.35, 0.0, ndl) * smoothstep(-0.2, 0.05, ndl);
	ALBEDO = mix(vec3(1.0), vec3(1.0, 0.72, 0.5), dusk * 0.6);
	ALPHA = smoothstep(0.08, 0.95, a) * 0.82;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
