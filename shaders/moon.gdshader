shader_type spatial;
#include "res://shaders/noise.gdshaderinc"
varying vec3 lpos;
void vertex() { lpos = VERTEX; }
float craters(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	float d = 1.0;
	for (int x = -1; x <= 1; x++)
	for (int y = -1; y <= 1; y++)
	for (int z = -1; z <= 1; z++) {
		vec3 o = vec3(float(x), float(y), float(z));
		vec3 h = vec3(hash13(i + o), hash13(i + o + 17.1), hash13(i + o + 41.7));
		d = min(d, length(o + h - f));
	}
	return d;
}
void fragment() {
	vec3 p = normalize(lpos);
	float maria = smoothstep(0.45, 0.6, fbm(p * 1.6 + 3.0));
	float n = fbm(p * 9.0);
	float c1 = craters(p * 7.0);
	float c2 = craters(p * 19.0);
	float rim = smoothstep(0.25, 0.32, c1) - smoothstep(0.32, 0.42, c1);
	float bowl = 1.0 - smoothstep(0.0, 0.3, c1);
	float g = 0.62 - maria * 0.25 + (n - 0.5) * 0.18 + rim * 0.12 - bowl * 0.08 - (1.0 - smoothstep(0.0, 0.2, c2)) * 0.06;
	ALBEDO = vec3(g) * vec3(1.0, 0.98, 0.95);
	ROUGHNESS = 0.95;
}
