shader_type sky;
#include "res://shaders/noise.gdshaderinc"
uniform float star_density = 0.996;

float star_layer(vec3 d, float scale, float thr) {
	vec3 p = d * scale;
	vec3 i = floor(p);
	vec3 f = fract(p) - 0.5;
	float h = hash13(i);
	if (h < thr) return 0.0;
	vec3 off = vec3(hash13(i + 7.0), hash13(i + 13.0), hash13(i + 29.0)) - 0.5;
	float dist = length(f - off * 0.6);
	float b = (h - thr) / (1.0 - thr);
	return smoothstep(0.12, 0.0, dist) * (0.4 + 1.6 * b);
}

void sky() {
	vec3 d = normalize(EYEDIR);
	vec3 col = vec3(0.004, 0.006, 0.018);
	float neb = fbm(d * 2.5 + vec3(5.0));
	float neb2 = fbm(d * 5.0 + vec3(11.0));
	float band = exp(-pow(dot(d, normalize(vec3(0.3, 1.0, 0.2))) * 3.0, 2.0));
	col += vec3(0.10, 0.04, 0.16) * smoothstep(0.45, 0.85, neb) * 0.6;
	col += vec3(0.02, 0.06, 0.14) * smoothstep(0.5, 0.9, neb2) * 0.6;
	col += vec3(0.05, 0.05, 0.07) * band * neb;
	float s = star_layer(d, 180.0, star_density) + star_layer(d, 420.0, star_density + 0.002) * 0.7;
	s += star_layer(d, 90.0, 0.9985) * 1.5;
	vec3 tint = mix(vec3(0.8, 0.85, 1.0), vec3(1.0, 0.9, 0.75), hash13(floor(d * 180.0)));
	col += s * tint;
	// sol
	float sun = max(dot(d, LIGHT0_DIRECTION), 0.0);
	col += vec3(1.0, 0.9, 0.7) * (pow(sun, 2000.0) * 40.0 + pow(sun, 80.0) * 0.4);
	COLOR = col;
}
