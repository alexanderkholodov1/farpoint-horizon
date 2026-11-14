shader_type spatial;
// The Earth from NASA data (assets/source/planet_textures.py): Blue Marble by day, Black Marble lights at night,
// hill shading from the Blue Marble relief, and the shadows of the real clouds of the cloud layer. As in photographs
// from orbit, the air scatters blue light over the day side, more toward the limb where the line of sight crosses
// more air, and reddens it near the terminator; the sea shows a small, sharp glint of the Sun.
uniform sampler2D day_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D night_tex : filter_linear_mipmap, repeat_enable;
uniform sampler2D relief_tex : filter_linear_mipmap, repeat_enable;
uniform sampler2D cloud_tex : filter_linear_mipmap, repeat_enable;
uniform vec3 sun_dir = vec3(0.0, 0.0, 1.0);   // world space, towards the Sun (set by World every frame)
uniform float cloud_shift = 0.0;               // the cloud layer's drift in U, so the shadows follow it
uniform vec3 haze : source_color = vec3(0.36, 0.58, 0.95);
uniform vec3 dusk : source_color = vec3(1.0, 0.5, 0.25);

void fragment() {
	vec3 c = texture(day_tex, UV).rgb;
	float ocean = smoothstep(0.02, 0.08, c.b - max(c.r, c.g * 0.8)) * (1.0 - smoothstep(0.18, 0.3, c.r));
	// relief: the shaded map's light, and a normal from its slopes so mountains catch the real Sun
	float rel = texture(relief_tex, UV).r;
	vec2 px = vec2(1.0 / 2048.0, 1.0 / 1024.0);
	float rx = texture(relief_tex, UV + vec2(px.x, 0.0)).r - texture(relief_tex, UV - vec2(px.x, 0.0)).r;
	float ry = texture(relief_tex, UV + vec2(0.0, px.y)).r - texture(relief_tex, UV - vec2(0.0, px.y)).r;
	NORMAL_MAP = normalize(vec3(-rx * 3.0, ry * 3.0, 1.0) * (1.0 - ocean) + vec3(0.0, 0.0, 1.0) * ocean) * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 1.0;
	c *= mix(1.0, clamp(rel * 2.0, 0.5, 1.5), 0.4 * (1.0 - ocean));
	float shadow = texture(cloud_tex, UV + vec2(cloud_shift + 0.0015, 0.001)).r;
	c *= 1.0 - shadow * 0.35;
	// the Blue Marble ocean is nearly black at game size; seen from orbit it reads deep blue
	c = mix(c, c * 1.4 + vec3(0.012, 0.04, 0.09), ocean);

	vec3 sv = normalize((VIEW_MATRIX * vec4(sun_dir, 0.0)).xyz);
	float ndl = dot(NORMAL, sv);
	float day = smoothstep(-0.12, 0.35, ndl);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.5);
	float twilight = smoothstep(-0.1, 0.03, ndl) * (1.0 - smoothstep(0.03, 0.18, ndl));
	// aerial perspective: blue haze over the day side, thicker toward the limb
	vec3 air = mix(haze, dusk, twilight * 0.5);
	c = mix(c, air, clamp(rim * 0.6 + 0.03, 0.0, 0.75) * day);
	ALBEDO = c * 1.1;
	ROUGHNESS = mix(0.92, 0.2, ocean);
	// no glare smeared along the limb: the glint fades well before grazing angles
	SPECULAR = mix(0.08, 0.5, ocean) * (1.0 - smoothstep(0.35, 0.8, 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0)));
	float night = smoothstep(0.08, -0.18, ndl);
	float lights = texture(night_tex, UV).r * (1.0 - shadow * 0.7);
	EMISSION = vec3(1.0, 0.68, 0.32) * lights * night * 2.2 + air * rim * day * 0.18;
}
