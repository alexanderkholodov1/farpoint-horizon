shader_type spatial;
render_mode blend_add, unshaded, cull_back, depth_draw_never;
// A thin glow at the limb, bright on the day side, orange where the day ends, gone on the night side.
uniform vec3 glow_color : source_color = vec3(0.32, 0.6, 1.0);
uniform vec3 dusk_color : source_color = vec3(1.0, 0.55, 0.25);
uniform float power = 4.0;
uniform float intensity = 1.5;
uniform vec3 sun_dir = vec3(0.0, 0.0, 1.0);
void fragment() {
	float f = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), power);
	vec3 sv = normalize((VIEW_MATRIX * vec4(sun_dir, 0.0)).xyz);
	float ndl = dot(NORMAL, sv);
	float day = smoothstep(-0.25, 0.35, ndl);
	float dusk = smoothstep(-0.3, 0.0, ndl) * smoothstep(0.35, 0.0, ndl);
	ALBEDO = (glow_color * day + dusk_color * dusk * 0.7) * f * intensity;
}
