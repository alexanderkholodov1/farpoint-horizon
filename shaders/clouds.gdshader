shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back;
#include "res://shaders/noise.gdshaderinc"
uniform float coverage = 0.55;
uniform float speed = 0.01;
varying vec3 lpos;
void vertex() { lpos = VERTEX; }
void fragment() {
	vec3 p = normalize(lpos);
	float lat = abs(p.y);
	float n = fbm(p * 4.0 + vec3(TIME * speed, 0.0, TIME * speed * 0.5));
	n += 0.15 * sin(p.y * 18.0 + n * 6.0);
	float band = mix(1.0, 0.85, smoothstep(0.1, 0.4, lat));
	float a = smoothstep(coverage, coverage + 0.18, n * band);
	ALBEDO = vec3(1.0);
	ALPHA = a * 0.85;
	ROUGHNESS = 1.0;
}
