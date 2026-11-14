shader_type spatial;
// The Earth from NASA data (assets/source/planet_textures.py): Blue Marble by day, Black Marble lights at night,
// hill shading from the Blue Marble relief, and the shadows of the real clouds of the cloud layer.
uniform sampler2D day_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D night_tex : filter_linear_mipmap, repeat_enable;
uniform sampler2D relief_tex : filter_linear_mipmap, repeat_enable;
uniform sampler2D cloud_tex : filter_linear_mipmap, repeat_enable;
uniform vec3 sun_dir = vec3(0.0, 0.0, 1.0);   // world space, towards the Sun (set by World every frame)
uniform float cloud_shift = 0.0;               // the cloud layer's drift in U, so the shadows follow it

void fragment() {
	vec3 c = texture(day_tex, UV).rgb;
	float rel = texture(relief_tex, UV).r;
	float ocean = smoothstep(0.02, 0.08, c.b - max(c.r, c.g * 0.8)) * (1.0 - smoothstep(0.18, 0.3, c.r));
	c *= mix(1.0, clamp(rel * 2.0, 0.4, 1.6), 0.55 * (1.0 - ocean));
	float shadow = texture(cloud_tex, UV + vec2(cloud_shift + 0.0015, 0.001)).r;
	c *= 1.0 - shadow * 0.35;
	// the Blue Marble ocean is nearly black at game size; seen from orbit it reads deep blue
	c = mix(c, c * 1.4 + vec3(0.012, 0.04, 0.09), ocean);
	ALBEDO = c * 1.12;
	ROUGHNESS = mix(0.9, 0.32, ocean);
	SPECULAR = mix(0.12, 0.65, ocean);
	vec3 sv = normalize((VIEW_MATRIX * vec4(sun_dir, 0.0)).xyz);
	float ndl = dot(NORMAL, sv);
	float night = smoothstep(0.08, -0.18, ndl);
	float lights = texture(night_tex, UV).r * (1.0 - shadow * 0.7);
	EMISSION = vec3(1.0, 0.68, 0.32) * lights * night * 2.2;
}
