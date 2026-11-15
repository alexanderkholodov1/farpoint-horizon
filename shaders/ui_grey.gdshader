shader_type canvas_item;
// A picture in grey and dimmed: a mission that is not open yet (scripts/screens/missions.gd).
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(vec3(g) * 0.55, c.a);
}
