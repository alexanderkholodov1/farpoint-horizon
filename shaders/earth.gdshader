shader_type spatial;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 night_color : source_color = vec3(1.0, 0.75, 0.35);

void fragment() {
	vec3 c = texture(albedo_tex, UV).rgb;
	float ocean = step(c.g * 1.25, c.b) * step(c.r, 0.3);
	ALBEDO = c;
	ROUGHNESS = mix(0.9, 0.45, ocean);
	SPECULAR = mix(0.2, 0.4, ocean);
}
