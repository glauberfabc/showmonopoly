shader_type canvas_item;
uniform vec2 extent = vec2(288.0, 65.0);
uniform vec4 tint : hint_color = vec4(0.08, 0.55, 0.16, 1.0);
uniform float pressed = 0.0;
uniform float disabled = 0.0;
uniform float hover = 0.0;
float rounded(vec2 p, vec2 half_size, float r) {
	vec2 q = abs(p) - half_size + vec2(r);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}
void fragment() {
	vec2 p = (UV - vec2(0.5)) * extent;
	float edge = rounded(p, extent * 0.5 - vec2(1.0, 2.0), 22.0);
	float inner = rounded(p - vec2(0.0, -2.0 + pressed * 3.0), extent * 0.5 - vec2(7.0, 8.0), 17.0);
	float y = UV.y;
	vec3 rim = mix(vec3(1.0, 0.91, 0.55), vec3(0.48, 0.29, 0.04), smoothstep(0.15, 0.95, y));
	rim += vec3(0.22) * exp(-pow((y - 0.16) * 24.0, 2.0));
	vec3 face = tint.rgb * mix(1.65, 0.55, y);
	face += vec3(0.30, 0.37, 0.20) * (1.0 - smoothstep(0.08, 0.48, y));
	face += vec3(0.16) * exp(-pow((y - 0.24) * 19.0, 2.0));
	face *= 1.0 + hover * 0.14 - pressed * 0.22;
	vec3 color = mix(rim, face, 1.0 - smoothstep(-1.0, 1.0, inner));
	color = mix(color, color * 0.45, disabled);
	COLOR = vec4(color, 1.0 - smoothstep(-1.0, 1.0, edge));
}
