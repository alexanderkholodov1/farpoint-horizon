shader_type spatial;
uniform vec3 cell_color : source_color = vec3(0.04, 0.07, 0.25);
uniform vec2 cells = vec2(8.0, 4.0);
void fragment() {
	vec2 g = fract(UV * cells);
	float line = step(0.965, g.x) + step(0.955, g.y);
	ALBEDO = mix(cell_color, vec3(0.32, 0.34, 0.38), clamp(line, 0.0, 1.0));
	METALLIC = 0.3;
	ROUGHNESS = mix(0.15, 0.5, clamp(line, 0.0, 1.0));
}
