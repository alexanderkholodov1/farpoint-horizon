shader_type spatial;
render_mode blend_add, unshaded, cull_back, depth_draw_never;
uniform vec3 glow_color : source_color = vec3(0.3, 0.6, 1.0);
uniform float power = 3.0;
uniform float intensity = 1.4;
void fragment() {
	float f = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), power);
	ALBEDO = glow_color * f * intensity;
}
