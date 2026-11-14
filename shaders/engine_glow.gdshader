shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never;
uniform vec3 glow : source_color = vec3(1.0, 0.6, 0.2);
uniform float strength = 2.0;
varying float vy;
void vertex() { vy = UV.y; }
void fragment() {
	float flick = 0.85 + 0.15 * sin(TIME * 40.0 + UV.x * 20.0);
	float f = pow(1.0 - clamp(dot(NORMAL, VIEW) * -1.0 + 1.0, 0.0, 1.0), 0.5);
	ALBEDO = glow * strength * flick * (1.0 - UV.y);
}
